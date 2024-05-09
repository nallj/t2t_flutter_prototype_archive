// TODO: Consider renaming this into something else, or merging with RequestStatus.
enum ViewState {
  NOT_SET,

  PROVIDER_NOT_CALLED,

  // Request Status States
  WAITING_FOR_PROVIDER,  // TODO: Consider changing to NO_PROVIDER_COMMITED
  PROVIDER_COMMITTED,
  PROVIDER_AT_SCENE,
  PROVIDER_TOWING,
  JOB_FINISHED,
  CUSTOMER_CANCELED,
  PROVIDER_CANCELED,
  CUSTOMER_CANCELED_AFTER_PROVIDER_CANCELED,
}
