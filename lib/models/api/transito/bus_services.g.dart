// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bus_services.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AllBusServices _$AllBusServicesFromJson(Map<String, dynamic> json) =>
    AllBusServices(
      metadata: json['odata.metadata'] as String,
      busServices: (json['value'] as List<dynamic>)
          .map((e) => BusServiceInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

BusStopServicesApiResponse _$BusStopServicesApiResponseFromJson(
        Map<String, dynamic> json) =>
    BusStopServicesApiResponse(
      count: json['count'] as int,
      data: (json['data'] as List<dynamic>).map((e) => e as String).toList(),
    );

BusServiceInfo _$BusServiceInfoFromJson(Map<String, dynamic> json) =>
    BusServiceInfo(
      serviceNo: json['serviceNo'] as String,
      operator: BusServiceInfo.decodeBusOperator(json['operator'] as String),
      isLoopService: json['isLoopService'] as bool,
      interchanges: (json['interchanges'] as List<dynamic>)
          .map((e) => SimpleBusStopInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      busRoutes: (json['busRoutes'] as List<dynamic>)
          .map((e) => BusRouteInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
