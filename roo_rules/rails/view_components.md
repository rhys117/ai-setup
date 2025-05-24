# ViewComponent Standards for Social Script Project

## Overview

This rule file establishes standards for ViewComponent usage in the project.

## Key Rules

1. **Directory Structure**
   - All components MUST be in `app/components/`
   - UI components MUST be in `app/components/ui/`
   - Namespace directories MUST match module structure

2. **Component Movement and Refactoring**
   - ❌ NEVER recreate components in new locations manually
   - ✅ ALWAYS use CLI commands to move components:
     ```bash
     # Moving a component
     mv app/components/episodes/row_component.rb app/components/ui/episodes/row/row_component.rb
     mv app/components/episodes/row_component.html.erb app/components/ui/episodes/row/row_component.html.erb
     ```
   - This preserves:
     - Git history
     - File timestamps
     - Exact content matching
     - Proper permissions

3. **File Organization**
   - ❌ NEVER create separate module definition files (e.g., ui.rb, navigation.rb)
   - ✅ Define modules within component files
   - One component per file
   - File name must match class name in snake_case

4. **Component Structure**
   ```ruby   
   class UI::Buttons::PrimaryButton < ApplicationComponent
     # Component code here
   end
   ```

## Validation Steps

When working with components:

1. Check file location matches namespace
2. Verify module nesting in component file
3. Validate documentation presence
4. Test component rendering
5. Verify CLI usage for moves

## Error Prevention

Common issues to avoid:

1. Creating separate module files
2. Mismatching namespaces and directories
3. Missing documentation
4. Incomplete module nesting
5. Manual component recreation
6. Flat component structure

## References

- ViewComponent configuration in `config/application.rb`
- Component previews in `spec/components/previews` or `test/components/previews`
