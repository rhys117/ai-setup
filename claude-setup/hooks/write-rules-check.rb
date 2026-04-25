#!/usr/bin/env ruby
# write-rules-check.rb - Enforce content + advisory rules on Edit/MultiEdit/Write.
#
# Reads stdin JSON from Claude Code and applies rules from
# .claude/hooks/write_rules.yml. Each rule:
#
#   type:              "block" (deny the tool call) or "warn" (inject context)
#   pattern:           Optional Ruby regex matched against the new content.
#                      Omit to fire on file-glob match alone.
#   context:           Static message returned to Claude.
#   context_script:    Optional path (relative to project root) to a script
#                      that emits the context dynamically. Receives
#                      CLAUDE_FILE_PATH, CLAUDE_RELATIVE_PATH, and
#                      CLAUDE_SESSION_ID via env. Stdout protocol:
#                        - Optional first line: "#sentinel-suffix:<value>"
#                          (suffix is appended to the per-session sentinel
#                          key, enabling per-target once_per_session).
#                        - Remaining lines: the context body.
#                      Empty body suppresses the rule. Overrides static
#                      `context` when both are set.
#   files:             Globs (relative to project root, ** supported).
#   once_per_session:  Optional, warn-only. When true, the rule fires at most
#                      once per session (sentinel under tmp/.claude-advisory/).
#                      Block rules ignore this flag - every Edit must be checked.
#
# Block rules surface as hookSpecificOutput.permissionDecision = "deny"
# (with permissionDecisionReason). Warn rules surface as additionalContext.

require 'fileutils'
require 'json'
require 'open3'
require 'yaml'

input = JSON.parse($stdin.read)
tool = input['tool_name']
session_id = input['session_id'].to_s
file_path = input.dig('tool_input', 'file_path').to_s
exit 0 if file_path.empty?

new_content = case tool
              when 'Edit'
                input.dig('tool_input', 'new_string').to_s
              when 'MultiEdit'
                Array(input.dig('tool_input', 'edits'))
                  .map { |edit| edit['new_string'].to_s }
                  .join("\n")
              when 'Write'
                input.dig('tool_input', 'content').to_s
              else
                exit 0
              end

project_dir = ENV['CLAUDE_PROJECT_DIR'].to_s
config_path = File.join(project_dir, '.claude', 'hooks', 'write_rules.yml')
exit 0 unless File.exist?(config_path)

rules = YAML.safe_load_file(config_path) || {}
exit 0 if rules.empty?

relative_path = if !project_dir.empty? && file_path.start_with?("#{project_dir}/")
                  file_path[(project_dir.length + 1)..]
                else
                  file_path
                end

fnmatch_flags = File::FNM_PATHNAME | File::FNM_DOTMATCH

session_dir = File.join(
  project_dir,
  'tmp',
  '.claude-advisory',
  session_id.empty? ? 'unknown-session' : session_id,
)

blocks = []
warns = []
warn_sentinels_to_touch = []

rules.each do |name, rule|
  next unless rule.is_a?(Hash)

  type = rule['type']
  pattern = rule['pattern']
  static_context = rule['context'].to_s
  context_script = rule['context_script'].to_s
  globs = Array(rule['files'])
  once = rule['once_per_session'] == true

  next unless %w[block warn].include?(type)
  next if static_context.empty? && context_script.empty?
  next if globs.empty?

  matches_file = globs.any? do |glob|
    File.fnmatch?(glob, relative_path, fnmatch_flags) ||
      File.fnmatch?(glob, file_path, fnmatch_flags)
  end
  next unless matches_file

  if pattern && !pattern.to_s.empty?
    begin
      regex = Regexp.new(pattern)
    rescue RegexpError
      warn "[write-rules-check] invalid regex for rule '#{name}': #{pattern}"
      next
    end
    next unless regex.match?(new_content)
  end

  context = static_context
  sentinel_suffix = nil

  unless context_script.empty?
    script_path = File.expand_path(context_script, project_dir)
    unless File.executable?(script_path)
      warn "[write-rules-check] context_script not executable for '#{name}': #{script_path}"
      next
    end

    env = {
      'CLAUDE_FILE_PATH' => file_path,
      'CLAUDE_RELATIVE_PATH' => relative_path,
      'CLAUDE_SESSION_ID' => session_id,
    }
    stdout_str, _status = Open3.capture2(env, script_path)
    lines = stdout_str.lines
    if lines.first&.start_with?('#sentinel-suffix:')
      sentinel_suffix = lines.shift.sub('#sentinel-suffix:', '').strip
    end
    body = lines.join.strip
    next if body.empty?

    context = body
  end

  if type == 'warn' && once
    sentinel_name = sentinel_suffix && !sentinel_suffix.empty? ? "#{name}-#{sentinel_suffix}" : name
    sentinel = File.join(session_dir, sentinel_name)
    next if File.exist?(sentinel)

    warn_sentinels_to_touch << sentinel
  end

  message = "[#{name}] #{context}"
  (type == 'block' ? blocks : warns) << message
end

if blocks.any?
  reason = (blocks + warns).join("\n\n")
  puts JSON.generate(
    hookSpecificOutput: {
      hookEventName: 'PreToolUse',
      permissionDecision: 'deny',
      permissionDecisionReason: reason,
    },
  )
  exit 2
elsif warns.any?
  warn_sentinels_to_touch.each do |sentinel|
    FileUtils.mkdir_p(File.dirname(sentinel))
    FileUtils.touch(sentinel)
  end
  puts JSON.generate(
    hookSpecificOutput: {
      hookEventName: 'PreToolUse',
      additionalContext: warns.join("\n\n"),
    },
  )
end

exit 0
