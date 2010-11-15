class UniqueFriendValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    # check for an inverse friend relationship on the record object
    if Friendship.where(:friend_id => record.user_id).where(:user_id => record.friend_id).count > 0
      record.errors[attribute] << "friendship already exists"
    end
  end
end