class Subscription < ActiveRecord::Base
  belongs_to :owner, :class_name => "User"

  has_many :accounts
  has_many :tags

  has_many :events do
    def recent(n=5)
      find(:all, :order => "created_at DESC", :limit => n, :include => :account_items)
    end

    def prepare(attrs={})
      event = build(:role => attrs[:role], :occurred_on => Date.today)

      case event.role
      when :reallocation
        event.actor = "Bucket reallocation"
        if attrs[:from]
          bucket = Bucket.find(attrs[:from])
          account = @owner.accounts.find(bucket.account_id)
          event.line_items.build(:role => "primary", :account => account, :bucket => bucket)
          event.line_items.build(:role => "reallocate_from", :account => account, :bucket => account.buckets.default)
        elsif attrs[:to]
          bucket = Bucket.find(attrs[:to])
          account = @owner.accounts.find(bucket.account_id)
          event.line_items.build(:role => "primary", :account => account, :bucket => bucket)
          event.line_items.build(:role => "reallocate_to", :account => account, :bucket => account.buckets.default)
        end
      end

      return event
    end
  end

  has_many :user_subscriptions
  has_many :users, :through => :user_subscriptions
end
