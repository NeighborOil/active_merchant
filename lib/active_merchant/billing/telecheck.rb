module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    # The Telecheck object is a plain old Ruby object, similar to Check, and CreditCard.  It supports validation
    # of necessary attributes such as checkholder's name, routing and account numbers, as required by Telecheck but it is
    # not backed by any database.
    # 
    # You may use Telecheck in place of CreditCard with any gateway that supports it. Currently, only
    # +FirstData+ supports the Telecheck object.
    class Telecheck
      include Validateable
      
      attr_accessor :first_name, :last_name, :address1, :address2, :city, :state, :zip, :phone, :email,
                    :routing, :account, :bankname, :bankstate, :dl, :dlstate, :void,
                    :accounttype, :ssn, :checknumber, :void
      
      # Used for Canadian bank accounts
      attr_accessor :institution_number, :transit_number
      
      def name
        @name ||= "#{@first_name} #{@last_name}".strip
      end
      
      def name=(value)
        return if value.blank?

        @name = value
        segments = value.split(' ')
        @last_name = segments.pop
        @first_name = segments.join(' ')
      end
      
      def validate
        [:first_name, :last_name, :address1, :city, :state, :zip, :phone, :email,
         :routing, :account, :bankname, :bankstate, :dl, :dlstate].each do |attr|
          errors.add(attr, "cannot be empty") if self.send(attr).blank?
        end

        [:state, :bankstate, :dlstate].each do |state|
          errors.add(state, "must be a valid US State Code") if valid_state_codes.include?(state.to_s)
        end

        errors.add(:routing, "is invalid") unless valid_routing_number?
        
        errors.add(:account_type, "must be personal or business, checking or savings") if
            !account_type.blank? && !%w[pc ps bc bs].include?(account_type.to_s)
      end
      
      def type
        'telecheck'
      end
      
      # Routing numbers may be validated by calculating a checksum and dividing it by 10. The
      # formula is:
      #   (3(d1 + d4 + d7) + 7(d2 + d5 + d8) + 1(d3 + d6 + d9))mod 10 = 0
      # See http://en.wikipedia.org/wiki/Routing_transit_number#Internal_checksums
      def valid_routing_number?
        d = routing_number.to_s.split('').map(&:to_i).select { |d| (0..9).include?(d) }
        case d.size
          when 9 then
            checksum = ((3 * (d[0] + d[3] + d[6])) +
                        (7 * (d[1] + d[4] + d[7])) +
                             (d[2] + d[5] + d[8])) % 10
            case checksum
              when 0 then true
              else        false
            end
          else false
        end
      end

      def valid_state_codes
        %w[AL AK AZ AR CA CO CT DE DC FL GA HI ID IL IN IA KS KY LA ME MD MA MN MS MO MT NE NV NH NJ NM NC ND OH OK OR PA RI SC SD TN TX UT VT VA WA WI WV WY]
      end
    end
  end
end
