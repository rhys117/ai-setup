#!/usr/bin/env ruby
# write-rules-check.rb - Enforce content + advisory rules on Edit/MultiEdit/Write.
#
# Reads stdin JSON from Claude Code and applies rules from
# .claude/hooks/write_rules.yml. Each rule:
#
#   type:              "block" (deny the tool call) or "warn" (inject context)
#   pattern:           Optional Ruby regex matched against the new content.
#                      Omit to fire on file-glob match alone.
#   context:           Message returned to Claude.
#   files:             Globs (relative to project root, ** supported).
#   once_per_session:  Optional, warn-only. When true, the rule fires at most
#                      once per session (sentinel under tmp/.claude-advisory/).
#                      Block rules ignore this flag - every Edit must be checked.
#
# Block rules surface as hookSpecificOutput.permissionDecision = "deny"
# (with permissionDecisionReason). Warn rules surface as additionalContext.

require 'fileutils'
require 'json'
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
  context = rule['context']
  globs = Array(rule['files'])
  once = rule['once_per_session'] == true

  next unless %w[block warn].include?(type)
  next if context.nil? || context.to_s.empty?
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

  if type == 'warn' && once
    sentinel = File.join(session_dir, name)
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
