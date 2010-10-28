class UniqueFriendValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    # attribute is 'user_id'
    # check that no friendship exists where friend_id == user_id
    record.errors[attribute] << "friendship already exists" if Friendship.where("friend_id = #{value}").count > 0
  end
end