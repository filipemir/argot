class FavoritesController < ApplicationController
  def index
    @artists = current_user.top_artists
  end
end
