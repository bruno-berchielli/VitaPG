# frozen_string_literal: true

class Layout::SidebarComponent < ApplicationComponent
  NavItem = Data.define(:key, :icon, :path)

  def nav_items
    [
      NavItem.new(key: :dashboard, icon: :home, path: root_path),
      NavItem.new(key: :backup_routines, icon: :archive, path: backup_routines_path),
      NavItem.new(key: :backup_runs, icon: :clock, path: backup_runs_path),
      NavItem.new(key: :database_connections, icon: :database, path: database_connections_path),
      NavItem.new(key: :destinations, icon: :server, path: destinations_path),
      NavItem.new(key: :notification_channels, icon: :bolt, path: notification_channels_path),
      NavItem.new(key: :memberships, icon: :users, path: memberships_path)
    ]
  end

  def active?(item)
    if item.key == :dashboard
      current_page?(root_path)
    else
      request.path.start_with?(item.path)
    end
  end

  def item_classes(item)
    base = "flex items-center gap-2.5 rounded-md px-2.5 py-1.5 text-sm font-medium transition-colors"

    if active?(item)
      "#{base} bg-primary-subtle text-primary"
    else
      "#{base} text-text-muted hover:bg-surface-highlight hover:text-text-main"
    end
  end

  def workspace = Current.workspace

  def user = Current.user

  def other_workspaces
    user.workspaces.where.not(id: workspace.id).order(:name)
  end
end
