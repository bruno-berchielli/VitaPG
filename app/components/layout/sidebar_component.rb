# frozen_string_literal: true

class Layout::SidebarComponent < ApplicationComponent
  NavItem = Data.define(:key, :icon, :path)

  def operations_items
    [
      NavItem.new(key: :dashboard, icon: :home, path: root_path),
      NavItem.new(key: :backup_routines, icon: :archive, path: backup_routines_path),
      NavItem.new(key: :backup_runs, icon: :clock, path: backup_runs_path),
      NavItem.new(key: :database_connections, icon: :database, path: database_connections_path),
      NavItem.new(key: :destinations, icon: :server, path: destinations_path)
    ]
  end

  def instance_items
    return [] unless user.superadmin?

    [ NavItem.new(key: :admin_users, icon: :users, path: admin_users_path) ]
  end

  def workspace_items
    [
      NavItem.new(key: :directory, icon: :building, path: workspaces_path),
      NavItem.new(key: :memberships, icon: :users, path: memberships_path),
      NavItem.new(key: :notification_channels, icon: :bolt, path: notification_channels_path),
      NavItem.new(key: :workspace_settings, icon: :cog, path: edit_workspace_path(Current.workspace))
    ]
  end

  def active?(item)
    if item.key == :dashboard
      current_page?(root_path)
    elsif item.key == :workspace_settings
      request.path.match?(%r{\A/workspaces/\d+/edit})
    elsif item.key == :directory
      request.path == workspaces_path || request.path == new_workspace_path
    elsif item.key == :admin_users
      request.path.start_with?("/admin")
    else
      request.path.start_with?(item.path)
    end
  end

  def item_classes(item)
    base = "flex items-center gap-3 rounded-full px-4 py-2.5 text-sm font-semibold transition-colors"

    if active?(item)
      "#{base} bg-ink text-on-ink shadow-soft"
    else
      "#{base} text-text-muted hover:bg-surface-highlight hover:text-text-main"
    end
  end

  def workspace = Current.workspace

  def user = Current.user

  def other_workspaces
    user.accessible_workspaces.where.not(id: workspace.id).order(:name)
  end

  def dark_mode?
    helpers.current_mode == "dark"
  end
end
