class SearchesController < ApplicationController
  RESULT_LIMIT = 10

  def show
    @query = params[:q].to_s.strip

    if @query.length >= 2
      pattern = "%#{ActiveRecord::Base.sanitize_sql_like(@query)}%"
      @routines = Current.workspace.backup_routines.where("name LIKE ?", pattern).limit(RESULT_LIMIT)
      @connections = Current.workspace.database_connections
                            .where("name LIKE ? OR host LIKE ? OR database_name LIKE ?", pattern, pattern, pattern)
                            .limit(RESULT_LIMIT)
      @destinations = Current.workspace.destinations
                             .where("name LIKE ? OR bucket LIKE ?", pattern, pattern)
                             .limit(RESULT_LIMIT)
    else
      @routines = @connections = @destinations = []
    end
  end
end
