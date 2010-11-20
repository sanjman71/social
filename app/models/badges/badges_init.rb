module Badges
  class Init
    # remove all roles and privileges
    def self.remove_all
      Badges::Privilege.destroy_all
      Badges::Role.destroy_all
    end

    def self.add_roles_and_privileges
      um = Badges::Role.find_or_create_by_name('user manager')
      add_user_privileges(um)
      {:roles => Badges::Role.count, :privileges => Badges::Privilege.count}
    end

    def self.add_user_privileges(um)
      # user privileges
      mu = Badges::Privilege.find_or_create_by_name(:name=>"manage users")
      ru = Badges::Privilege.find_or_create_by_name(:name=>"read users")

      # user managers can manage and read users
      Badges::RolePrivilege.create(:role => um, :privilege=>mu)
      Badges::RolePrivilege.create(:role => um, :privilege=>ru)
    end
  end
end