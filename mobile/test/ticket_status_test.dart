import 'package:flutter_test/flutter_test.dart';
import 'package:beresapp/domain/entities/ticket_status.dart';

void main() {
  group('TicketStatus State Machine Tests', () {
    test('State machine codes and labels map properly', () {
      expect(TicketStatus.fromCode('OPEN'), TicketStatus.open);
      expect(TicketStatus.fromCode('BIDDING'), TicketStatus.bidding);
      expect(TicketStatus.fromCode('LOCKED'), TicketStatus.locked);
      expect(TicketStatus.fromCode('ON_THE_WAY'), TicketStatus.onTheWay);
      expect(TicketStatus.fromCode('ARRIVED'), TicketStatus.arrived);
      expect(TicketStatus.fromCode('IN_PROGRESS'), TicketStatus.inProgress);
      expect(TicketStatus.fromCode('WORK_COMPLETED'), TicketStatus.workCompleted);
      expect(TicketStatus.fromCode('PAYMENT_PENDING'), TicketStatus.paymentPending);
      expect(TicketStatus.fromCode('COMPLETED'), TicketStatus.completed);
      expect(TicketStatus.fromCode('CANCELED'), TicketStatus.canceled);
      // Unknown fallback
      expect(TicketStatus.fromCode('UNKNOWN_CODE'), TicketStatus.open);
    });

    test('Cancellation directly allowed only on open, bidding, and locked', () {
      expect(TicketStatus.open.canUserCancelDirectly, isTrue);
      expect(TicketStatus.bidding.canUserCancelDirectly, isTrue);
      expect(TicketStatus.locked.canUserCancelDirectly, isTrue);

      expect(TicketStatus.onTheWay.canUserCancelDirectly, isFalse);
      expect(TicketStatus.arrived.canUserCancelDirectly, isFalse);
      expect(TicketStatus.inProgress.canUserCancelDirectly, isFalse);
      expect(TicketStatus.workCompleted.canUserCancelDirectly, isFalse);
      expect(TicketStatus.paymentPending.canUserCancelDirectly, isFalse);
      expect(TicketStatus.completed.canUserCancelDirectly, isFalse);
      expect(TicketStatus.canceled.canUserCancelDirectly, isFalse);
    });

    test('isTrackingActive is true only when onTheWay', () {
      expect(TicketStatus.onTheWay.isTrackingActive, isTrue);
      expect(TicketStatus.open.isTrackingActive, isFalse);
      expect(TicketStatus.inProgress.isTrackingActive, isFalse);
      expect(TicketStatus.completed.isTrackingActive, isFalse);
    });

    test('isActive returns false for completed and canceled', () {
      expect(TicketStatus.completed.isActive, isFalse);
      expect(TicketStatus.canceled.isActive, isFalse);

      expect(TicketStatus.open.isActive, isTrue);
      expect(TicketStatus.bidding.isActive, isTrue);
      expect(TicketStatus.locked.isActive, isTrue);
      expect(TicketStatus.onTheWay.isActive, isTrue);
      expect(TicketStatus.arrived.isActive, isTrue);
      expect(TicketStatus.inProgress.isActive, isTrue);
      expect(TicketStatus.workCompleted.isActive, isTrue);
      expect(TicketStatus.paymentPending.isActive, isTrue);
    });
  });
}
