# frozen_string_literal: true

ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

  content title: proc { I18n.t("active_admin.dashboard") } do
    # Statistics Cards - All counts on one row
    div class: "flex flex-wrap gap-4 mb-8" do
      # Users card
      link_to admin_users_path, class: "flex-1 min-w-0 bg-white dark:bg-gray-800 overflow-hidden shadow-lg rounded-xl border border-gray-200 dark:border-gray-700 hover:shadow-xl transition-shadow duration-200 no-underline" do
        div class: "p-4 text-center" do
          div class: "text-3xl mb-2" do
            "👤"
          end
          div class: "text-2xl font-bold text-gray-900 dark:text-gray-100 mb-1" do
            User.count.to_s
          end
          div class: "text-xs font-medium text-gray-500 dark:text-gray-400" do
            "Total Users"
          end
        end
      end

      # Series card
      link_to admin_series_index_path, class: "flex-1 min-w-0 bg-white dark:bg-gray-800 overflow-hidden shadow-lg rounded-xl border border-gray-200 dark:border-gray-700 hover:shadow-xl transition-shadow duration-200 no-underline" do
        div class: "p-4 text-center" do
          div class: "text-3xl mb-2" do
            "📺"
          end
          div class: "text-2xl font-bold text-gray-900 dark:text-gray-100 mb-1" do
            Series.count.to_s
          end
          div class: "text-xs font-medium text-gray-500 dark:text-gray-400" do
            "Total Series"
          end
        end
      end

      # Episodes card
      link_to admin_episodes_path, class: "flex-1 min-w-0 bg-white dark:bg-gray-800 overflow-hidden shadow-lg rounded-xl border border-gray-200 dark:border-gray-700 hover:shadow-xl transition-shadow duration-200 no-underline" do
        div class: "p-4 text-center" do
          div class: "text-3xl mb-2" do
            "🎬"
          end
          div class: "text-2xl font-bold text-gray-900 dark:text-gray-100 mb-1" do
            Episode.count.to_s
          end
          div class: "text-xs font-medium text-gray-500 dark:text-gray-400" do
            "Total Episodes"
          end
        end
      end

      # User-Series connections card
      link_to admin_users_path, class: "flex-1 min-w-0 bg-white dark:bg-gray-800 overflow-hidden shadow-lg rounded-xl border border-gray-200 dark:border-gray-700 hover:shadow-xl transition-shadow duration-200 no-underline" do
        div class: "p-4 text-center" do
          div class: "text-3xl mb-2" do
            "🔗"
          end
          div class: "text-2xl font-bold text-gray-900 dark:text-gray-100 mb-1" do
            UserSeries.count.to_s
          end
          div class: "text-xs font-medium text-gray-500 dark:text-gray-400" do
            "User Subscriptions"
          end
        end
      end
    end

    # Sync Status Cards - Second row
    users_needing_sync = User.select(&:needs_sync?).count
    series_needing_sync = Series.select(&:needs_sync?).count
    
    div class: "flex flex-wrap gap-8 mb-10" do
      # Users needing sync
      div class: "flex-1 min-w-0 bg-white dark:bg-gray-800 overflow-hidden shadow-lg rounded-xl border border-gray-200 dark:border-gray-700" do
        div class: "p-8 text-center" do
          div class: "w-20 h-20 #{users_needing_sync > 0 ? 'bg-yellow-500' : 'bg-green-500'} rounded-full flex items-center justify-center mx-auto mb-6" do
            span users_needing_sync > 0 ? "⚠️" : "✅", class: "text-white text-3xl"
          end
          div class: "text-5xl font-bold text-gray-900 dark:text-gray-100 mb-3" do
            users_needing_sync.to_s
          end
          div class: "text-xl font-semibold text-gray-900 dark:text-gray-100 mb-2" do
            "Users Needing Sync"
          end
          div class: "text-base text-gray-500 dark:text-gray-400" do
            users_needing_sync > 0 ? "#{users_needing_sync} users need syncing" : "All users are up to date"
          end
        end
      end

      # Series needing sync
      div class: "flex-1 min-w-0 bg-white dark:bg-gray-800 overflow-hidden shadow-lg rounded-xl border border-gray-200 dark:border-gray-700" do
        div class: "p-8 text-center" do
          div class: "w-20 h-20 #{series_needing_sync > 0 ? 'bg-yellow-500' : 'bg-green-500'} rounded-full flex items-center justify-center mx-auto mb-6" do
            span series_needing_sync > 0 ? "⚠️" : "✅", class: "text-white text-3xl"
          end
          div class: "text-5xl font-bold text-gray-900 dark:text-gray-100 mb-3" do
            series_needing_sync.to_s
          end
          div class: "text-xl font-semibold text-gray-900 dark:text-gray-100 mb-2" do
            "Series Needing Sync"
          end
          div class: "text-base text-gray-500 dark:text-gray-400" do
            series_needing_sync > 0 ? "#{series_needing_sync} series need syncing" : "All series are up to date"
          end
        end
      end
    end

    # Recent Activity
    div class: "flex flex-wrap gap-6" do
      # Recent Users
      div class: "flex-1 min-w-0 bg-white dark:bg-gray-800 overflow-hidden shadow rounded-lg" do
        div class: "px-4 py-5 sm:p-6" do
          h3 "Recent Users", class: "text-lg font-medium text-gray-900 dark:text-gray-100 mb-4"
          recent_users = User.order(created_at: :desc).limit(5)
          
          if recent_users.any?
            div class: "space-y-3" do
              recent_users.each do |user|
                div class: "flex items-center justify-between py-2 border-b border-gray-200 dark:border-gray-700 last:border-b-0" do
                  div do
                    strong do
                      link_to "User #{user.id}", admin_user_path(user), class: "text-sm font-medium text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300 no-underline"
                    end
                    para "PIN: #{user.pin[0..1]}******", class: "text-xs text-gray-500 dark:text-gray-400"
                  end
                  div class: "text-right" do
                    para time_ago_in_words(user.created_at) + " ago", class: "text-xs text-gray-500 dark:text-gray-400"
                    para "#{user.series.count} series", class: "text-xs text-gray-500 dark:text-gray-400"
                  end
                end
              end
            end
          else
            para "No users yet", class: "text-sm text-gray-500 dark:text-gray-400"
          end
        end
      end

      # Recent Series
      div class: "flex-1 min-w-0 bg-white dark:bg-gray-800 overflow-hidden shadow rounded-lg" do
        div class: "px-4 py-5 sm:p-6" do
          h3 "Recent Series", class: "text-lg font-medium text-gray-900 dark:text-gray-100 mb-4"
          recent_series = Series.order(created_at: :desc).limit(5)
          
          if recent_series.any?
            div class: "space-y-3" do
              recent_series.each do |series|
                div class: "flex items-center justify-between py-2 border-b border-gray-200 dark:border-gray-700 last:border-b-0" do
                  div do
                    strong do
                      link_to series.name, admin_series_path(series), class: "text-sm font-medium text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300 no-underline"
                    end
                    para "TVDB ID: #{series.tvdb_id}", class: "text-xs text-gray-500 dark:text-gray-400"
                  end
                  div class: "text-right" do
                    para time_ago_in_words(series.created_at) + " ago", class: "text-xs text-gray-500 dark:text-gray-400"
                    para "#{series.episodes.count} episodes", class: "text-xs text-gray-500 dark:text-gray-400"
                  end
                end
              end
            end
          else
            para "No series yet", class: "text-sm text-gray-500 dark:text-gray-400"
          end
        end
      end
    end
  end
end
