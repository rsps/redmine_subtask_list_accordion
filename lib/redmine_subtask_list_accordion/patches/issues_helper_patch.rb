require 'issues_helper'

module RedmineSubtaskListAccordion
  module Patches
    module IssuesHelperPatch
      # Allows methods to be called directly as module functions, bypassing Rails 8 helper isolation
      module_function

      def render_descendants_tree(issue)
        if sla_has_grandson_issues?(issue) && !subtask_tree_client_processing?
          render_descendants_tree_accordion(issue)
        else
          super(issue)
        end
      end

      def render_descendants_tree_accordion(issue)
        trIdx = 0
        s = '<table class="list issues odd-even">'

        issue_list(issue.descendants.visible.preload(:status, :priority, :tracker, :assigned_to).sort_by(&:lft)) do |child, level|
          arrow = (child.descendants.visible.count > 0 ? content_tag('span', '', :class => 'treearrow') : ''.html_safe)

          css = "issue issue-#{child.id} hascontextmenu #{child.css_classes}"
          css << " haschild" if child.children?
          css << (expand_tree_at_first?(issue) ? " expand" : " collapse")
          css << " idnt idnt-#{level}" if level > 0

          hide_or_show = 'display: none;' unless level <= 0 || expand_tree_at_first?(issue)

          s << content_tag('tr',
                content_tag('td', check_box_tag("ids[]", child.id, false, :id => nil), :class => 'checkbox') +
                content_tag('td', arrow + link_to_issue(child, :project => (issue.project_id != child.project_id)), :class => 'subject', :style => 'width: 50%') +
                content_tag('td', h(child.status), :class => 'status') +
                content_tag('td', link_to_user(child.assigned_to), :class => 'assigned_to') +
                content_tag('td', child.start_date, :class => 'start_date') +
                content_tag('td', child.due_date, :class => 'due_date') +
                content_tag('td', child.disabled_core_fields.include?('done_ratio') ? '' : progress_bar(child.done_ratio), :class=> 'done_ratio'),
                :class => css, :cs => (trIdx+=1).to_s, :ce => (trIdx + child.descendants.visible.count - 1).to_s, :rank => level.to_s, :style => hide_or_show)
        end
        s << '</table>'
        s.html_safe
      end

      def expand_tree_at_first?(issue)
        limit = User.current.pref.respond_to?(:subtasks_default_expand_limit_upper) ? User.current.pref.subtasks_default_expand_limit_upper : 5
        return issue.descendants.visible.count <= limit
      end

      def sla_has_grandson_issues?(issue)
        return issue.descendants.visible.where(["issues.parent_id <> ?", issue.id]).count > 0
      end

      def subtask_tree_client_processing?
        return true if Setting.plugin_redmine_subtask_list_accordion.nil?
        return !Setting.plugin_redmine_subtask_list_accordion['enable_server_scripting_mode']
      end

      def sla_use_css
        "subtask_list_accordion"
      end
    end
  end
end
