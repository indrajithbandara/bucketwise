class LineItem < ActiveRecord::Base
  include Pageable

  VALID_ROLES = %w(payment_source
                   credit_options
                   transfer_to
                   transfer_from
                   deposit
                   reallocate_to
                   reallocate_from
                   aside
                   primary)

  # 'primary' role is omitted, as it is something of a special case
  VALID_ROLE_GROUPS = {
    "payment_source"  => %w(payment_source credit_options aside),
    "credit_options"  => %w(payment_source credit_options aside),
    "transfer_to"     => %w(transfer_from transfer_to),
    "transfer_from"   => %w(transfer_from transfer_to),
    "deposit"         => %w(deposit),
    "reallocate_to"   => %w(primary reallocate_to),
    "reallocate_from" => %w(reallocate_from primary),
    "aside"           => %w(payment_source credit_options aside)
  }

  belongs_to :event
  belongs_to :account
  belongs_to :bucket

  after_create :increment_bucket_balance
  before_destroy :decrement_bucket_balance

  named_scope :expenses, :conditions => ["role in (?)", ['payment_source', 'transfer_from', 'credit_options']]
  named_scope :deposits, :conditions => ["role in (?)", ['deposit', 'transfer_to']]
  named_scope :reallocations, :conditions => ["role in (?)", %w(primary aside reallocate_from reallocate_to)]
  named_scope :on_or_after, lambda { |date| { :conditions => ["occurred_on >= ?", date.to_date] } }
  named_scope :on_or_before, lambda { |date| { :conditions => ["occurred_on <= ?", date.to_date] } }

  def to_xml(options={})
    options[:except] = Array(options[:except])
    options[:except].concat [:event_id, :occurred_on, :id]
    super(options)
  end

  protected

    def increment_bucket_balance
      bucket.update_attribute :balance, bucket.balance + amount
    end

    def decrement_bucket_balance
      bucket.update_attribute :balance, bucket.balance - amount
    end
end
