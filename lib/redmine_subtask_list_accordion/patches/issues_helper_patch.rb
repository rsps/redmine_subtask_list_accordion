require_dependency("issues_helper")

module RedmineSubtaskListAccordion
  module Patches
    module IssuesHelperPatch
      extend ActiveSupport::Concern

      #wrap original method
      #Changed: Now includes modified original method, to add start_date and due_date to subtasks
      #Todo: These should be refactored away. See https://stackoverflow.com/questions/59041480/improving-on-hacky-ruby-method-alias-fix-for-conflicting-redmine-plugins
      included do
        #alias_method :render_descendants_tree_original, :render_descendants_tree
        alias_method :render_descendants_tree, :switch_render_descendants_tree
        alias_method :sla_use_css, :sla_use_css
        alias_method :switch_render_descendants_tree, :switch_render_descendants_tree
        alias_method :render_descendants_tree_original, :render_descendants_tree_original
        alias_method :render_descendants_tree_accordion, :render_descendants_tree_accordion
        alias_method :expand_tree_at_first?,  :expand_tree_at_first?
        alias_method :sla_has_grandson_issues?, :sla_has_grandson_issues?
        alias_method :subtask_tree_client_processing?, :subtask_tree_client_processing?
        alias_method :subtask_list_accordion_tree_render_32?, :subtask_list_accordion_tree_render_32?
        alias_method :subtask_list_accordion_tree_render_33?, :subtask_list_accordion_tree_render_33?
        alias_method :subtask_list_accordion_tree_render_34?, :subtask_list_accordion_tree_render_34?
      end

      #switch by enable condition
      def switch_render_descendants_tree(issue)
        if sla_has_grandson_issues?(issue) &&  !subtask_tree_client_processing?
          render_descendants_tree_accordion(issue)
        else
          render_descendants_tree_original(issue)
        end
      end

      def render_descendants_tree_original(issue)
        s = '<table class="list issues odd-even">'
        issue_list(issue.descendants.visible.preload(:status, :priority, :tracker, :assigned_to).sort_by(&:lft)) do |child, level|
          css = "issue issue-#{child.id} hascontextmenu #{child.css_classes}"
          css << " idnt idnt-#{level}" if level > 0
          s << content_tag('tr',
                 content_tag('td', check_box_tag("ids[]", child.id, false, :id => nil), :class => 'checkbox') +
                 content_tag('td', link_to_issue(child, :project => (issue.project_id != child.project_id)), :class => 'subject', :style => 'width: 50%') +
                 content_tag('td', h(child.status), :class => 'status') +
                 content_tag('td', link_to_user(child.assigned_to), :class => 'assigned_to') +
                 content_tag('td', child.start_date, :class => 'start_date') +
                 content_tag('td', child.due_date, :class => 'due_date') +
                 content_tag('td', child.disabled_core_fields.include?('done_ratio') ? '' : progress_bar(child.done_ratio), :class=> 'done_ratio') +
                 content_tag('td', link_to_context_menu, :class => 'buttons'),
                 :class => css)
        end
        s << '</table>'
        s.html_safe
      end

      # add method to IssuesHelper
      def render_descendants_tree_accordion(issue)
        trIdx = 0
        #switch by redmine version
        if subtask_list_accordion_tree_render_32?
          s = '<form><table class="list issues">'
          issue_list(issue.descendants.visible.preload(:status, :priority, :tracker).sort_by(&:lft)) do |child, level|
            arrow = (child.descendants.visible.count > 0 ? content_tag('span', '', :class => 'treearrow') : ''.html_safe)
            css = "issue issue-#{child.id} hascontextmenu"
            css << " haschild" if child.children?
            css << (expand_tree_at_first?(issue) ? " expand" : " collapse")
            css << " idnt idnt-#{level}" if level > 0
            hide_or_show = 'display: none;' unless level <= 0 || expand_tree_at_first?(issue)
            s << content_tag('tr',
                  content_tag('td', check_box_tag("ids[]", child.id, false, :id => nil), :class => 'checkbox') +
                  content_tag('td', arrow + link_to_issue(child, :project => (issue.project_id != child.project_id)), :class => 'subject', :style => 'width: 50%') +
                  content_tag('td', h(child.status)) +
                  content_tag('td', link_to_user(child.assigned_to)) +
                  content_tag('td', child.start_date) +
                  content_tag('td', child.due_date) +
                  content_tag('td', child.disabled_core_fields.include?('done_ratio') ? '' : progress_bar(child.done_ratio)),
                  :class => css, :cs => (trIdx+=1).to_s, :ce => (trIdx + child.descendants.visible.count - 1).to_s, :rank => level.to_s, :style => hide_or_show)
          end
          s << '</table></form>'
          s.html_safe
        else
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
                  content_tag('td', child.disabled_core_fields.include?('done_ratio') ? '' : progress_bar(child.done_ratio), :class=> 'done_ratio') +
                  #Compatible 3.4 under
                  (subtask_list_accordion_tree_render_34? ? '' : content_tag('td', link_to_context_menu, :class => 'buttons')),
                  :class => css, :cs => (trIdx+=1).to_s, :ce => (trIdx + child.descendants.visible.count - 1).to_s, :rank => level.to_s, :style => hide_or_show)
          end
          s << '</table>'
          #Compatible 3.3 under
          subtask_list_accordion_tree_render_33? ? ('<form>' + s + '</form>').html_safe : s.html_safe
        end
      end

      def expand_tree_at_first?(issue)
        return issue.descendants.visible.count <= User.current.pref.subtasks_default_expand_limit_upper
      end

      def sla_has_grandson_issues?(issue)
        return issue.descendants.visible.where(["issues.parent_id <> ?", issue.id]).count > 0
      end

      def subtask_tree_client_processing?
        return !Setting.plugin_redmine_subtask_list_accordion['enable_server_scripting_mode']
      end

      def subtask_list_accordion_tree_render_32?
        threshold = [3,3,0]
        return (Redmine::VERSION.to_a[0, 3] <=> threshold) < 0
      end

      def subtask_list_accordion_tree_render_33?
        threshold = [3,4,0]
        return (Redmine::VERSION.to_a[0, 3] <=> threshold) < 0
      end

      def subtask_list_accordion_tree_render_34?
        threshold = [4,0,0]
        return (Redmine::VERSION.to_a[0, 3] <=> threshold) < 0
      end

      def sla_use_css
        case
        when subtask_list_accordion_tree_render_32?
          "subtask_list_accordion_under32"
        when subtask_list_accordion_tree_render_34?
          "subtask_list_accordion_under34"
        else
          "subtask_list_accordion"
        end
      end
    end
  end
end
