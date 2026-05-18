import 'package:meetmap_addis/shared/models/event_model.dart';

final EventModel featuredEvent = const EventModel(
  id: 'featured_1',
  title: 'Addis Startup Mixer',
  category: 'Networking',
  location: 'GreenHouse Addis, Bole',
  date: 'Sat, Nov 2',
  time: '5:00 PM',
  host: 'StartupAddis',
  imageUrl:
      'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?auto=format&fit=crop&w=1200&q=80',
  attendeeCount: 142,
  description:
      'The biggest startup networking event of the month. Meet founders, investors, and builders shaping the future of Addis.',
  isFeatured: true,
);

final List<EventModel> mockEvents = [
  const EventModel(
    id: '1',
    title: 'Ethiopian Coffee Tasting',
    category: 'Coffee',
    location: 'Tomoca Coffee, Bole',
    date: 'Fri, Oct 27',
    time: '6:00 PM',
    host: 'Tomoca Heritage',
    imageUrl:
        'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=800&q=80',
    attendeeCount: 24,
    description:
        'A curated journey through Ethiopia\'s finest single-origin coffees, led by expert roasters.',
  ),
  const EventModel(
    id: '2',
    title: 'Cultural Networking Night',
    category: 'Networking',
    location: 'Hyatt Regency Terrace',
    date: 'Sat, Oct 28',
    time: '4:30 PM',
    host: 'Connect Addis',
    imageUrl:
        'https://images.unsplash.com/photo-1540575467063-178a50c2df87?auto=format&fit=crop&w=800&q=80',
    attendeeCount: 110,
    description:
        'Mix and mingle with professionals across industries at Addis Ababa\'s premier rooftop terrace.',
  ),
  const EventModel(
    id: '3',
    title: 'Acoustic Soul Session',
    category: 'Music',
    location: 'The Warehouse, Sarbet',
    date: 'Sun, Oct 29',
    time: '7:00 PM',
    host: 'Sarbet Sounds',
    imageUrl:
        'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?auto=format&fit=crop&w=800&q=80',
    attendeeCount: 42,
    description:
        'An intimate evening of live acoustic performances celebrating Ethiopian and global soul music.',
  ),
  const EventModel(
    id: '4',
    title: 'Flutter Dev Meetup',
    category: 'Tech',
    location: 'Addis Abeba University, CMC',
    date: 'Mon, Oct 30',
    time: '2:00 PM',
    host: 'GDG Addis',
    imageUrl:
        'https://images.unsplash.com/photo-1591115765373-5207764f72e7?auto=format&fit=crop&w=800&q=80',
    attendeeCount: 65,
    description:
        'Monthly meetup for Flutter and Dart enthusiasts. Share projects, explore new features, and learn together.',
  ),
  const EventModel(
    id: '5',
    title: 'Community Book Club',
    category: 'Community',
    location: 'Sheba Café, Kazanchis',
    date: 'Tue, Oct 31',
    time: '10:00 AM',
    host: 'Addis Reads',
    imageUrl:
        'https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?auto=format&fit=crop&w=800&q=80',
    attendeeCount: 18,
    description:
        'This month we\'re discussing "Things Fall Apart." All readers welcome — bring your thoughts and coffee.',
  ),
  const EventModel(
    id: '6',
    title: 'Women in Startup Panel',
    category: 'Startup',
    location: 'Impact Hub Addis',
    date: 'Wed, Nov 1',
    time: '3:30 PM',
    host: 'SheLeadsAddis',
    imageUrl:
        'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?auto=format&fit=crop&w=800&q=80',
    attendeeCount: 78,
    description:
        'Hear from five inspiring women founders navigating the Ethiopian startup ecosystem.',
  ),
];
