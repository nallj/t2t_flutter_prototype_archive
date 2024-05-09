enum RequestStatusType {
  NOT_SET,
  WAITING_FOR_PROVIDER, // TODO: Consider changing to NO_PROVIDER_COMMITED
  PROVIDER_COMMITTED,
  PROVIDER_AT_SCENE,
  PROVIDER_TOWING,
  JOB_FINISHED,
  CUSTOMER_CANCELED,
  // When a provider cancels on a committed job, the customer is asked if they want their request to continue.
  // If not, this is the end result.
  PROVIDER_CANCELED,
  CUSTOMER_CANCELED_AFTER_PROVIDER_CANCELED, // TODO: Added a 'providerBrokenAgreementCount' to a request record.
}

class RequestStatus {
  static const String WAITING_FOR_PROVIDER = 'waiting_for_provider';
  static const String PROVIDER_COMMITTED = 'provider_committed';
  static const String PROVIDER_AT_SCENE = 'provider_at_scene';
  static const String PROVIDER_TOWING = 'provider_towing';
  static const String JOB_FINISHED = 'job_finished';
  static const String CUSTOMER_CANCELED = 'customer_canceled';
  static const String PROVIDER_CANCELED = 'provider_canceled';
  static const String CUSTOMER_CANCELED_AFTER_PROVIDER_CANCELED = 'customer_canceled_after_provider_canceled';

  // TODO: Find a better home for this.
  static isCommitedStatus(RequestStatusType status) =>
    status != RequestStatusType.WAITING_FOR_PROVIDER &&
    status != RequestStatusType.JOB_FINISHED &&
    status != RequestStatusType.CUSTOMER_CANCELED &&
    status != RequestStatusType.PROVIDER_CANCELED &&
    status != RequestStatusType.CUSTOMER_CANCELED_AFTER_PROVIDER_CANCELED;

  static toRequestStatusType(String status) {
    switch (status) {
      case RequestStatus.WAITING_FOR_PROVIDER:
        return RequestStatusType.WAITING_FOR_PROVIDER;
      case RequestStatus.PROVIDER_COMMITTED:
        return RequestStatusType.PROVIDER_COMMITTED;
      case RequestStatus.PROVIDER_AT_SCENE:
        return RequestStatusType.PROVIDER_AT_SCENE;
      case RequestStatus.PROVIDER_TOWING:
        return RequestStatusType.PROVIDER_TOWING;
      case RequestStatus.JOB_FINISHED:
        return RequestStatusType.JOB_FINISHED;
      case RequestStatus.CUSTOMER_CANCELED:
        return RequestStatusType.CUSTOMER_CANCELED;
      case RequestStatus.CUSTOMER_CANCELED_AFTER_PROVIDER_CANCELED:
        return RequestStatusType.CUSTOMER_CANCELED_AFTER_PROVIDER_CANCELED;
    }
    throw Exception('Unknown service status selected.');
  }

  static getDbString(RequestStatusType status) {
    switch (status) {
      case RequestStatusType.WAITING_FOR_PROVIDER:
        return RequestStatus.WAITING_FOR_PROVIDER;
      case RequestStatusType.PROVIDER_COMMITTED:
        return RequestStatus.PROVIDER_COMMITTED;
      case RequestStatusType.PROVIDER_AT_SCENE:
        return RequestStatus.PROVIDER_AT_SCENE;
      case RequestStatusType.PROVIDER_TOWING:
        return RequestStatus.PROVIDER_TOWING;
      case RequestStatusType.JOB_FINISHED:
        return RequestStatus.JOB_FINISHED;
      case RequestStatusType.CUSTOMER_CANCELED:
        return RequestStatus.CUSTOMER_CANCELED;
      case RequestStatusType.CUSTOMER_CANCELED_AFTER_PROVIDER_CANCELED:
        return RequestStatus.CUSTOMER_CANCELED_AFTER_PROVIDER_CANCELED;
    }
    throw Exception('Unknown service status selected.');
  }
}
