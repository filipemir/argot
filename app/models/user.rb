class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, omniauth_providers: [:lastfm]

  has_many :favorites
  has_many :artists, through: :favorites

  include HTTParty
  base_uri 'http://ws.audioscrobbler.com/2.0/'

  def update
    update_info && update_favorites("overall", 10)
    save
  end

  def top_artists(timeframe = "overall", number = 10)
    favorites.select do |fave|
      fave.timeframe ==  timeframe && fave.rank <= number
    end 
  end

  def self.from_omniauth(auth)
    where(provider: auth.provider, username: auth.uid).first_or_create do |user|
      user.password = Devise.friendly_token[0,20]
      user.name = auth.info.name
      user.image = auth.info.image
      user.playcount = auth.extra.raw_info.playcount
      user.update_favorites
    end
  end

  private

  def update_info
    
  end

  def update_favorites(timeframe = "overall", number = 10)
    artists_info = get_top_artists(timeframe, number)
    if artists_info
      artists_info.each do |artist_info|
        artist = Artist.where(name: artist_info['name']).first_or_create
        fave = Favorite.where(user: self, artist: artist, timeframe: timeframe).first_or_create
        fave.rank = artist_info['@attr']['rank'].to_i
        fave.playcount = artist_info['playcount']
        fave.save
      end
    else 
      false
    end
  end

  def email_required?
    false
  end

  def get_top_artists(timeframe, number)
    result = lastfm_query(
      method: 'user.gettopartists',
      user: username,
      period: timeframe,
      limit: number
    )
    result ? result['topartists']['artist'] : false
  end

  def lastfm_query(params)
    begin
      params = params.merge(
        api_key: ENV['LASTFM_KEY'], 
        format: 'json'
      )
      response = self.class.get('', query: params)
      response.keys.include?('error')? false : response
    rescue
      false
    end
  end
end
