// ignore_for_file: constant_identifier_names

/// HTTP response status codes
class HttpResponse {
  /// HTTP continue
  static const HTTP_CONTINUE = 100;

  /// HTTP switching protocols
  static const HTTP_SWITCHING_PROTOCOLS = 101;

  /// HTTP processing
  static const HTTP_PROCESSING = 102; // RFC2518

  /// HTTP early hints
  static const HTTP_EARLY_HINTS = 103; // RFC8297

  /// HTTP OK
  static const HTTP_OK = 200;

  /// HTTP created
  static const HTTP_CREATED = 201;

  /// HTTP accepted
  static const HTTP_ACCEPTED = 202;

  /// HTTP non-authoritative information
  static const HTTP_NON_AUTHORITATIVE_INFORMATION = 203;

  /// HTTP no content
  static const HTTP_NO_CONTENT = 204;

  /// HTTP reset content
  static const HTTP_RESET_CONTENT = 205;

  /// HTTP partial content
  static const HTTP_PARTIAL_CONTENT = 206;

  /// HTTP multi-status
  static const HTTP_MULTI_STATUS = 207; // RFC4918

  /// HTTP already reported
  static const HTTP_ALREADY_REPORTED = 208; // RFC5842

  /// HTTP IM used
  static const HTTP_IM_USED = 226; // RFC3229

  /// HTTP multiple choices
  static const HTTP_MULTIPLE_CHOICES = 300;

  /// HTTP moved permanently
  static const HTTP_MOVED_PERMANENTLY = 301;

  /// HTTP found
  static const HTTP_FOUND = 302;

  /// HTTP see other
  static const HTTP_SEE_OTHER = 303;

  /// HTTP not modified
  static const HTTP_NOT_MODIFIED = 304;

  /// HTTP use proxy
  static const HTTP_USE_PROXY = 305;

  /// HTTP reserved
  static const HTTP_RESERVED = 306;

  /// HTTP temporary redirect
  static const HTTP_TEMPORARY_REDIRECT = 307;

  /// HTTP permanently redirect
  static const HTTP_PERMANENTLY_REDIRECT = 308; // RFC7238

  /// HTTP bad request
  static const HTTP_BAD_REQUEST = 400;

  /// HTTP unauthorized
  static const HTTP_UNAUTHORIZED = 401;

  /// HTTP payment required
  static const HTTP_PAYMENT_REQUIRED = 402;

  /// HTTP forbidden
  static const HTTP_FORBIDDEN = 403;

  /// HTTP not found
  static const HTTP_NOT_FOUND = 404;

  /// HTTP method not allowed
  static const HTTP_METHOD_NOT_ALLOWED = 405;

  /// HTTP not acceptable
  static const HTTP_NOT_ACCEPTABLE = 406;

  /// HTTP proxy authentication required
  static const HTTP_PROXY_AUTHENTICATION_REQUIRED = 407;

  /// HTTP request timeout
  static const HTTP_REQUEST_TIMEOUT = 408;

  /// HTTP conflict
  static const HTTP_CONFLICT = 409;

  /// HTTP gone
  static const HTTP_GONE = 410;

  /// HTTP length required
  static const HTTP_LENGTH_REQUIRED = 411;

  /// HTTP precondition failed
  static const HTTP_PRECONDITION_FAILED = 412;

  /// HTTP request entity too large
  static const HTTP_REQUEST_ENTITY_TOO_LARGE = 413;

  /// HTTP request URI too long
  static const HTTP_REQUEST_URI_TOO_LONG = 414;

  /// HTTP unsupported media type
  static const HTTP_UNSUPPORTED_MEDIA_TYPE = 415;

  /// HTTP requested range not satisfiable
  static const HTTP_REQUESTED_RANGE_NOT_SATISFIABLE = 416;

  /// HTTP expectation failed
  static const HTTP_EXPECTATION_FAILED = 417;

  /// HTTP I am a teapot
  static const HTTP_I_AM_A_TEAPOT = 418; // RFC2324

  /// HTTP misdirected request
  static const HTTP_MISDIRECTED_REQUEST = 421; // RFC7540

  /// HTTP unprocessable entity
  static const HTTP_UNPROCESSABLE_ENTITY = 422; // RFC4918

  /// HTTP locked
  static const HTTP_LOCKED = 423; // RFC4918

  /// HTTP failed dependency
  static const HTTP_FAILED_DEPENDENCY = 424; // RFC4918

  /// HTTP too early
  static const HTTP_TOO_EARLY = 425; // RFC-ietf-httpbis-replay-04

  /// HTTP upgrade required
  static const HTTP_UPGRADE_REQUIRED = 426; // RFC2817

  /// HTTP precondition required
  static const HTTP_PRECONDITION_REQUIRED = 428; // RFC6585

  /// HTTP too many requests
  static const HTTP_TOO_MANY_REQUESTS = 429; // RFC6585

  /// HTTP request header fields too large
  static const HTTP_REQUEST_HEADER_FIELDS_TOO_LARGE = 431; // RFC6585

  /// HTTP unavailable for legal reasons
  static const HTTP_UNAVAILABLE_FOR_LEGAL_REASONS = 451;

  /// HTTP internal server error
  static const HTTP_INTERNAL_SERVER_ERROR = 500;

  /// HTTP not implemented
  static const HTTP_NOT_IMPLEMENTED = 501;

  /// HTTP bad gateway
  static const HTTP_BAD_GATEWAY = 502;

  /// HTTP service unavailable
  static const HTTP_SERVICE_UNAVAILABLE = 503;

  /// HTTP gateway timeout
  static const HTTP_GATEWAY_TIMEOUT = 504;

  /// HTTP version not supported
  static const HTTP_VERSION_NOT_SUPPORTED = 505;

  /// HTTP variant also negotiates experimental
  static const HTTP_VARIANT_ALSO_NEGOTIATES_EXPERIMENTAL = 506; // RFC2295

  /// HTTP insufficient storage
  static const HTTP_INSUFFICIENT_STORAGE = 507; // RFC4918

  /// HTTP loop detected
  static const HTTP_LOOP_DETECTED = 508; // RFC5842

  /// HTTP not extended
  static const HTTP_NOT_EXTENDED = 510; // RFC2774

  /// HTTP network authentication required
  static const HTTP_NETWORK_AUTHENTICATION_REQUIRED = 511; // RFC6585
}
