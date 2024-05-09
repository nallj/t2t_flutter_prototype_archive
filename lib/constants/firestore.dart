const COLLECTION_ACTIVE_REQUEST_CONSUMER = 'active_request_consumer';
const COLLECTION_ACTIVE_REQUEST_PROVIDER = 'active_request_provider';
const COLLECTION_BUSINESS = 'business';
const COLLECTION_FLEET_VEHICLE = 'fleet_vehicle';
const COLLECTION_REQUEST = 'request';
const COLLECTION_UPLOADED_IMAGE = 'uploaded_image';
const COLLECTION_USER = 'user';

// Unique to request record.
const requestIdKeyInQuestion = 'requestId';
const userIdKey = 'userId';
const requestCustomerKey = 'customer'; // TODO: consider using UserTypes
const requestProviderKey = 'provider'; // TODO: consider using UserTypes
const requestOriginKey = 'origin';
const requestDestinationKey = 'destination';
const latitudeKey = 'latitude';
const longitudeKey = 'longitude';
const headingKey = 'heading';
const statusKey = 'status';
const requestTimestampKey = 'requestTimestamp';

// Unique to Active request, consumer
const isActiveKey = 'isActive';

// Unique to user record.
const userTypeKey = 'type';
const locationTimestampKey = 'locationTimestamp';
const assignedFleetVehicleIdKey = 'assignedFleetVehicleId';

// Unique to fleet_vehicle record.
const fleetIdKey = 'fleetId';

// Unique to uploaded_image.
const bucketFileKey = 'bucketFile';

// Common keys.
const iconIdKey = 'iconId';
const idKey = 'id';
const typeKey = 'type';
const nameKey = 'name';
const emailKey = 'email';
const phoneKey = 'phone';
const businessIdKey = 'businessId';
const colorKey = 'color';
const makeKey = 'make';
const modelKey = 'model';

typedef FirestoreMap = Map<String, dynamic>;

