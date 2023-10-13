// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'arrival_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BusArrivalInfo _$BusArrivalInfoFromJson(Map<String, dynamic> json) =>
    BusArrivalInfo(
      metadata: json['odata.metadata'] as String,
      busStopCode: json['BusStopCode'] as String,
      services: (json['Services'] as List<dynamic>)
          .map((e) => ServiceInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

ServiceInfo _$ServiceInfoFromJson(Map<String, dynamic> json) => ServiceInfo(
      serviceNum: json['ServiceNo'] as String,
      busOperator: ServiceInfo.decodeBusOperator(json['Operator'] as String),
      nextBus:
          IndivArrivalInfo.fromJson(json['NextBus'] as Map<String, dynamic>),
      nextBus2:
          IndivArrivalInfo.fromJson(json['NextBus2'] as Map<String, dynamic>),
      nextBus3:
          IndivArrivalInfo.fromJson(json['NextBus3'] as Map<String, dynamic>),
    );

IndivArrivalInfo _$IndivArrivalInfoFromJson(Map<String, dynamic> json) =>
    IndivArrivalInfo(
      json['OriginCode'] as String?,
      json['DestinationCode'] as String?,
      json['EstimatedArrival'] as String?,
      IndivArrivalInfo.stringToDouble(json['Latitude'] as String),
      IndivArrivalInfo.stringToDouble(json['Longitude'] as String),
      IndivArrivalInfo.stringToInt(json['VisitNumber'] as String),
      IndivArrivalInfo.decodeCrowdLvl(json['Load'] as String),
      IndivArrivalInfo.decodeIsAccessible(json['Feature'] as String),
      IndivArrivalInfo.decodeBusType(json['Type']),
    );
