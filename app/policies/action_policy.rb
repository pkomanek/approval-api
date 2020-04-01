class ActionPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      # Must through a request
      raise Exceptions::NotAuthorizedError, "Not authorized to directly access actions" if scope == Action
      scope
    end
  end

  def create?
    permission_check('create', record) ? validate_create_action : false
  end

  def show?
    resource_check('read')
  end

  private

  def validate_create_action
    operation = user.params.require(:operation)
    uuid = user.request.headers['x-rh-random-access-key']

    valid_operation =
      admin?(record, 'create') && Action::ADMIN_OPERATIONS.include?(operation) ||
      approver?(record, 'create') && Action::APPROVER_OPERATIONS.include?(operation) ||
      requester?(record, 'create') && Action::REQUESTER_OPERATIONS.include?(operation) ||

      uuid.present? && Request.find(user.params[:request_id]).try(:random_access_keys).any? { |key| key.access_key == uuid }
  end
end
