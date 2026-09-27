import 'package:flutter_test/flutter_test.dart';
import 'package:guangheng/models/backend_models.dart';
import 'package:guangheng/repositories/backend_repository.dart';
import 'package:guangheng/services/backend_api_client.dart';
import 'package:guangheng/viewmodels/backend_view_model.dart';

class _NotificationRepository extends BackendRepository {
  _NotificationRepository(this.result)
    : super(BackendApiClient(baseUrl: 'http://test'));

  final BackendSnapshot result;

  @override
  Future<BackendSnapshot> load() async => result;
}

BackendSnapshot _notificationSnapshot() => BackendSnapshot(
  autonomy: const AutonomyStatus(
    agentState: 'ACTION_REQUIRED',
    enabled: true,
    unreadCount: 3,
  ),
  notifications: [
    NotificationEventModel(
      id: 8,
      type: 'PROPOSAL_CREATED',
      title: '需要你的确认',
      message: '建议调整备电计划',
      status: 'UNREAD',
      createdAt: DateTime(2026, 9, 23, 22),
    ),
  ],
);

void main() {
  test(
    'backend refresh forwards real unread events to local notifications',
    () async {
      List<NotificationEventModel>? events;
      int? unreadCount;
      final viewModel = BackendViewModel(
        _NotificationRepository(_notificationSnapshot()),
        notificationSync: (nextEvents, nextCount) async {
          events = nextEvents;
          unreadCount = nextCount;
        },
      );
      addTearDown(viewModel.dispose);

      await viewModel.load();

      expect(events?.single.id, 8);
      expect(unreadCount, 3);
      expect(viewModel.error, isNull);
    },
  );

  test('notification failure never hides valid backend data', () async {
    final viewModel = BackendViewModel(
      _NotificationRepository(_notificationSnapshot()),
      notificationSync: (_, _) async => throw StateError('permission denied'),
    );
    addTearDown(viewModel.dispose);

    await viewModel.load();

    expect(viewModel.data?.notifications.single.id, 8);
    expect(viewModel.error, isNull);
  });
}
