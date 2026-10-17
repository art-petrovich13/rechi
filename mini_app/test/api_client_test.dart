import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mini_app/core/api_client.dart';
import 'package:mini_app/core/api_exception.dart';
import 'package:mini_app/models/assessment.dart';
import 'package:mini_app/models/auth_response.dart';
import 'package:mini_app/models/exercise.dart';
import 'package:mini_app/models/progress.dart';

http.Response _jsonResponse(Object body, {int status = 200}) {
  return http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    status,
    headers: <String, String>{'content-type': 'application/json; charset=utf-8'},
  );
}

void main() {
  group('ApiClient.authTelegram', () {
    test('отправляет initData и парсит ответ', () async {
      final MockClient client = MockClient((http.Request request) async {
        expect(request.method, 'POST');
        expect(request.url.toString(), 'https://api.example.com/api/auth/telegram');
        expect(request.headers['content-type'], contains('application/json'));
        final Map<String, Object?> body =
            jsonDecode(request.body) as Map<String, Object?>;
        expect(body['initData'], 'query_id=1&hash=abc');

        return _jsonResponse(<String, Object?>{
          'token': 'jwt-token',
          'user': <String, Object?>{'id': 1, 'first_name': 'Иван'},
        });
      });

      final ApiClient api = ApiClient(
        baseUrl: 'https://api.example.com/',
        httpClient: client,
      );
      final AuthResponse response = await api.authTelegram(
        'query_id=1&hash=abc',
      );

      expect(response.token, 'jwt-token');
      expect(response.user.firstName, 'Иван');
    });

    test('отдаёт понятную ошибку для 401', () async {
      final MockClient client = MockClient((http.Request request) async {
        return _jsonResponse(
          <String, Object?>{'detail': 'Invalid initData'},
          status: 401,
        );
      });

      final ApiClient api = ApiClient(
        baseUrl: 'https://api.example.com',
        httpClient: client,
      );

      await expectLater(
        api.authTelegram('bad'),
        throwsA(
          isA<ApiException>()
              .having((ApiException e) => e.statusCode, 'status', 401)
              .having((ApiException e) => e.isUnauthorized, 'unauthorized', true)
              .having(
                (ApiException e) => e.serverDetail,
                'detail',
                'Invalid initData',
              ),
        ),
      );
    });
  });

  group('ApiClient.nextExercise', () {
    test('ставит Bearer-токен и читает упражнение', () async {
      final MockClient client = MockClient((http.Request request) async {
        expect(request.headers['Authorization'], 'Bearer jwt');
        expect(request.url.path, '/api/exercises/next');

        return _jsonResponse(<String, Object?>{
          'id': 5,
          'text': 'рыба',
          'phonemes': <String>['Р', 'Ы', 'Б', 'А'],
          'difficulty': 2,
        });
      });

      final ApiClient api = ApiClient(
        baseUrl: 'https://api.example.com',
        httpClient: client,
      )..setToken('jwt');

      final Exercise exercise = await api.nextExercise();

      expect(exercise.id, 5);
      expect(exercise.phonemes, <String>['Р', 'Ы', 'Б', 'А']);
    });
  });

  group('ApiClient.progress', () {
    test('читает прогресс', () async {
      final MockClient client = MockClient((http.Request request) async {
        return _jsonResponse(<String, Object?>{
          'attempts_count': 42,
          'weak_phonemes': <Map<String, Object?>>[
            <String, Object?>{'phoneme': 'Р', 'avg_score': 52},
          ],
        });
      });

      final ApiClient api = ApiClient(
        baseUrl: 'https://api.example.com',
        httpClient: client,
      )..setToken('jwt');

      final Progress progress = await api.progress();

      expect(progress.attemptsCount, 42);
      expect(progress.weakPhonemes.single.phoneme, 'Р');
    });

    test('маппит 502 в ошибку сервиса', () async {
      final MockClient client = MockClient((http.Request request) async {
        return _jsonResponse(
          <String, Object?>{'detail': 'Speech service unavailable'},
          status: 502,
        );
      });

      final ApiClient api = ApiClient(
        baseUrl: 'https://api.example.com',
        httpClient: client,
      )..setToken('jwt');

      await expectLater(
        api.progress(),
        throwsA(
          isA<ApiException>()
              .having(
                (ApiException e) => e.isServiceUnavailable,
                'service unavailable',
                true,
              )
              .having(
                (ApiException e) => e.userMessage,
                'message',
                contains('недоступен'),
              ),
        ),
      );
    });

    test('сообщает об отсутствии сети', () async {
      final MockClient client = MockClient((http.Request request) async {
        throw http.ClientException('network down');
      });

      final ApiClient api = ApiClient(
        baseUrl: 'https://api.example.com',
        httpClient: client,
      )..setToken('jwt');

      await expectLater(
        api.progress(),
        throwsA(
          isA<ApiException>().having(
            (ApiException e) => e.isNetwork,
            'network',
            true,
          ),
        ),
      );
    });
  });

  group('ApiClient.assess', () {
    test('отправляет multipart с аудио и exercise_id', () async {
      final MockClient client = MockClient((http.Request request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/assess');
        expect(request.headers['Authorization'], 'Bearer jwt');
        expect(request.headers['content-type'], startsWith('multipart/form-data'));

        final String body = utf8.decode(
          request.bodyBytes,
          allowMalformed: true,
        );
        expect(body, contains('name="audio"'));
        expect(body, contains('name="exercise_id"'));
        expect(body, contains('5'));

        return _jsonResponse(<String, Object?>{
          'score': 78,
          'phoneme_scores': <String, Object?>{
            'Р': 45,
            'Ы': 88,
            'Б': 90,
            'А': 95,
          },
          'problematic': <String>['Р'],
        });
      });

      final ApiClient api = ApiClient(
        baseUrl: 'https://api.example.com',
        httpClient: client,
      )..setToken('jwt');

      final Assessment assessment = await api.assess(
        audio: Uint8List.fromList(<int>[1, 2, 3, 4]),
        exerciseId: 5,
      );

      expect(assessment.score, 78);
      expect(assessment.problematic, <String>['Р']);
    });
  });
}
