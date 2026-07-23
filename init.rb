require_relative './lib/redmine_subtask_list_accordion/hooks/subtask_list_accordion_hook'
require_relative './lib/redmine_subtask_list_accordion/patches/issues_helper_patch'
require_relative './lib/redmine_subtask_list_accordion/patches/user_preference_patch'

# Reloader logic execution targeting Redmine 7.0 / Rails 8 environment
Rails.configuration.to_prepare do
  unless UserPreference.included_modules.include?(RedmineSubtaskListAccordion::Patches::UserPreferencePatch)
    UserPreference.send :prepend, RedmineSubtaskListAccordion::Patches::UserPreferencePatch
  end

  # Prepend the patch to ensure 'render_descendants_tree' is intercepted
  unless IssuesHelper.included_modules.include?(RedmineSubtaskListAccordion::Patches::IssuesHelperPatch)
    IssuesHelper.prepend(RedmineSubtaskListAccordion::Patches::IssuesHelperPatch)
  end

  # Ensure the helper patch is registered within IssuesController views
  unless IssuesController.helpers.include?(RedmineSubtaskListAccordion::Patches::IssuesHelperPatch)
    IssuesController.helper(RedmineSubtaskListAccordion::Patches::IssuesHelperPatch)
  end
end

Redmine::Plugin.register :redmine_subtask_list_accordion do
  name 'Redmine Subtask List Accordion plugin'
  author 'Ryuta Tobita, Steffen Brummer'
  description 'This plugin provide accordion to subtask list of issue. With extra subtask fields.'
  version '2.4.0'
  url 'https://github.com/rsps/redmine_subtask_list_accordion'
  author_url 'https://github.com/rsps/'
  settings default: { 'enable_server_scripting_mode' => true }, partial: 'settings/subtask_list_accordion_settings'
  requires_redmine :version_or_higher => '6.0.0'
end
