import 'package:meetmap_addis/shared/models/hangout_model.dart';

// ── Active / Featured hangout ─────────────────────────────────────────────

final HangoutModel activeHangout = const HangoutModel(
  id: 'h_active_1',
  title: 'Tech Talk at Tomoca',
  category: 'Business',
  location: 'Tomoca Coffee, Bole',
  time: '14:30',
  imageUrl:
      'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?auto=format&fit=crop&w=1200&q=80',
  attendeeCount: 5,
  description:
      'Discussing the latest local startup scene. Join us for the best macchiato in the city.',
  isLive: true,
);

// ── Quick hangout cards ───────────────────────────────────────────────────

final List<HangoutModel> quickHangouts = [
  const HangoutModel(
    id: 'h_quick_1',
    title: 'Strategy Brunch',
    category: 'Business',
    location: 'Kuriftu Diplomat',
    time: 'Starting in 45m',
    imageUrl:
        'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?auto=format&fit=crop&w=800&q=80',
    attendeeCount: 8,
    description: 'Relaxed Sunday brunch and strategy session.',
  ),
  const HangoutModel(
    id: 'h_quick_2',
    title: 'Study Sprint',
    category: 'Study',
    location: 'Sheba Café, Kazanchis',
    time: 'Starting in 1h 20m',
    imageUrl:
        'https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?auto=format&fit=crop&w=800&q=80',
    attendeeCount: 4,
    description: 'Focused study session with Pomodoro breaks.',
  ),
];

// ── Top pick venues ───────────────────────────────────────────────────────

final List<VenueModel> topPickVenues = [
  const VenueModel(
    id: 'v_1',
    name: 'Alem Bunna',
    location: 'Bole',
    rating: 4.8,
    imageUrl:
        'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?auto=format&fit=crop&w=800&q=80',
  ),
  const VenueModel(
    id: 'v_2',
    name: 'The Cup',
    location: 'Sarbet',
    rating: 4.6,
    imageUrl:
        'https://images.unsplash.com/photo-1550966871-3ed3cdb5ed0c?auto=format&fit=crop&w=800&q=80',
  ),
  const VenueModel(
    id: 'v_3',
    name: 'Kaldi\'s Arat Kilo',
    location: 'Arat Kilo',
    rating: 4.5,
    imageUrl:
        'https://images.unsplash.com/photo-1517701604599-bb29b565090c?auto=format&fit=crop&w=800&q=80',
  ),
];

// ── Recent activity ───────────────────────────────────────────────────────

final List<ActivityModel> recentActivities = [
  const ActivityModel(
    id: 'a_1',
    authorName: 'Maya Tesfaye',
    message: '"Just arrived at the cafe! I\'ve grabbed a table by the window."',
    timestamp: 'now',
    avatarUrl:
        'https://i.pravatar.cc/150?img=47',
  ),
  const ActivityModel(
    id: 'a_2',
    authorName: 'Design Collective',
    message: 'Elias sent a photo of the meeting room setup.',
    timestamp: '15m ago',
    hasGroupIcon: true,
  ),
  const ActivityModel(
    id: 'a_3',
    authorName: 'Kaleab Alemu',
    message: '"Running 10 mins late — order without me!"',
    timestamp: '28m ago',
    avatarUrl:
        'https://i.pravatar.cc/150?img=11',
  ),
];
