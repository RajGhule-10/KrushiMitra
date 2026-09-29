import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/api/api_client.dart';
import 'package:frontend/core/api/api_endpoints.dart';
import 'package:frontend/core/storage/token_store.dart';
import 'package:frontend/features/farms/data/farm_boundary_api.dart';
import 'package:frontend/features/farms/data/farm_boundary_repository.dart';
import 'package:frontend/features/farms/data/models/farm_boundary.dart';

class _FakeTokenStore implements TokenStore {
  @override
  Future<void> saveAccessToken(String token) async {}

  @override
  Future<String?> getAccessToken() async => null;

  @override
  Future<void> clearAccessToken() async {}
}

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.responseData);

  final Map<String, dynamic> responseData;
  late String method;
  late String path;
  Object? requestData;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    method = options.method;
    path = options.path;
    requestData = options.data;
    return ResponseBody.fromString(
      jsonEncode(responseData),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

ApiClient _apiClient(_RecordingAdapter adapter) {
  final client = ApiClient(tokenStore: _FakeTokenStore());
  client.dio.httpClientAdapter = adapter;
  return client;
}

const polygonGeometry = {
  'type': 'Polygon',
  'coordinates': [
    [
      [73.8, 18.5],
      [73.81, 18.5],
      [73.81, 18.51],
      [73.8, 18.5],
    ],
  ],
};

const multiPolygonGeometry = {
  'type': 'MultiPolygon',
  'coordinates': [
    [
      [
        [73.8, 18.5],
        [73.81, 18.5],
        [73.81, 18.51],
        [73.8, 18.5],
      ],
    ],
  ],
};

Map<String, dynamic> boundaryResponse({
  Map<String, dynamic> geometry = multiPolygonGeometry,
}) {
  return {'farm_id': 'farm-123', 'geometry': geometry};
}

void main() {
  test('parses and preserves Polygon geometry', () {
    final boundary = FarmBoundary.fromJson({
      'farm_id': 'farm-123',
      'geometry': polygonGeometry,
    });

    expect(boundary.id, isNull);
    expect(boundary.farmId, 'farm-123');
    expect(boundary.geometry.type, 'Polygon');
    expect(boundary.geometry.coordinates, polygonGeometry['coordinates']);
    expect(boundary.geometry.toJson(), polygonGeometry);
  });

  test('parses and preserves MultiPolygon geometry', () {
    final boundary = FarmBoundary.fromJson(boundaryResponse());

    expect(boundary.geometry.type, 'MultiPolygon');
    expect(boundary.geometry.coordinates, multiPolygonGeometry['coordinates']);
  });

  test('constructs the boundary endpoint with the farm ID', () {
    expect(
      ApiEndpoints.farmBoundary('farm-123'),
      '/api/v1/farms/farm-123/boundary',
    );
  });

  test('GET API and repository use the farm boundary endpoint', () async {
    final adapter = _RecordingAdapter(boundaryResponse());
    final repository = FarmBoundaryRepository(
      FarmBoundaryApi(_apiClient(adapter)),
    );

    final boundary = await repository.getBoundary('farm-123');

    expect(adapter.method, 'GET');
    expect(adapter.path, '/api/v1/farms/farm-123/boundary');
    expect(boundary.farmId, 'farm-123');
  });

  test('PUT API and repository preserve geometry in the request', () async {
    final adapter = _RecordingAdapter(boundaryResponse());
    final repository = FarmBoundaryRepository(
      FarmBoundaryApi(_apiClient(adapter)),
    );

    final boundary = await repository.saveBoundary('farm-123', polygonGeometry);

    expect(adapter.method, 'PUT');
    expect(adapter.path, '/api/v1/farms/farm-123/boundary');
    expect(adapter.requestData, polygonGeometry);
    expect(boundary.geometry.type, 'MultiPolygon');
  });
}
