require 'rails_helper'

RSpec.describe User do

  let(:user) { FactoryGirl.create(:user, username: 'gopigasus') }
  let(:non_existing_user_hash) do
    OmniAuth::AuthHash.new({
        "provider" => "lastfm",
        "uid" => "i_d0_n0t_exist_1931",
        "info" => {"name" => nil, "image" => "fake-image.png"},
        "extra" => {"raw_info" => {"playcount" => "665"}}
      })
  end

  describe '#from_omniauth:' do
    it 'returns user if user already exists' do
      result = User.from_omniauth(mock_auth_hash)
      expect(result).to be_a(User)
      expect(result.persisted?).to be(true)
    end

    it 'creates and returns persisted user if user did not previously exist' do
      result = User.from_omniauth(non_existing_user_hash)
      expect(result).to be_a(User)
      expect(result.persisted?).to be(true)
    end
  end

  describe '#username' do
    it 'returns username' do
      expect(user.username).to eq('gopigasus')
    end
  end

  describe '#image' do
    it 'returns url of user profile picture' do
      expect(user.image).to eq('sample-image.png')
    end
  end

  describe '#playcount' do
    it 'returns user playcount' do
      expect(user.playcount).to be_a Integer
      expect(user.playcount).to be > 0
    end
  end

  describe '#top_artists' do
    before :each do
      FAVORITES_NUM.times { FactoryGirl.create(:favorite, user: user) }
    end

    it 'returns top 10 artists in user favorites' do
      expect(user.top_artists.length).to eq(FAVORITES_NUM)
      expect(user.top_artists.sample).to be_a Artist
    end

    it 'returns artists sorted by rank in ascending order' do
      ranks = user.top_artists.map do |artist|
        favorite = Favorite.find_by(
          user: user,
          artist: artist,
          timeframe: FAVORITES_TIMEFRAME
        )
        favorite.rank
      end
      i = 1
      while i < ranks.length
        expect(ranks[i]).to be >= ranks[i - 1]
        i += 1
      end
    end
  end

  context 'Updates' do
    before :each do
      user.image = 'another_image.jpg'
      user.playcount = 2
      user.save
    end

    describe '#update_favorites' do
      it 'updates user top artists' do
        user.update_favorites
        expect(user.top_artists.length).to eq(FAVORITES_NUM)
        expect(user.top_artists.sample).to be_a Artist
      end

      it 'saves lastfm images to artists' do
        user.update_favorites
        expect(user.top_artists.sample.lastfm_image).to be_a String
        ranks = user.top_artists.map do |artist|
          favorite = Favorite.find_by(
            user: user,
            artist: artist,
            timeframe: FAVORITES_TIMEFRAME
          )
          favorite.rank
        end
        i = 1
        while i < ranks.length
          expect(ranks[i]).to be >= ranks[i - 1]
          i += 1
        end
      end
    end

    describe '#update_info' do
      before :each do
        user.update_info
        user.save
      end

      it 'updates username' do
        expect(user.username).to eq('gopigasus')
      end

      it 'updates user image' do
        expect(user.image).to eq('https://lastfm-img2.akamaized.net/i/u/300x300/3986da997db38257ff069000e7467d32.png')
      end

      it 'updates user playcount' do
        expect(user.playcount).to be >= 46500
      end

      it 'returns false if user does not exist in last.fm' do
        fake_user = User.from_omniauth(non_existing_user_hash)
        expect(fake_user.update_info).to eq(false)
      end
    end
  end

end
