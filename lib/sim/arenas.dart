import 'arena.dart';
import 'geometry.dart';

/// The campaign: 20 hand-authored arenas.
///
/// GENERATED, then checked in. Geometry (target positions, blocks, deflectors)
/// is hand-authored in `tools/solver/campaign.js`. Every *number* that affects
/// difficulty is not: `requiredBanks`, `shots` and `starThresholds` are produced
/// by running the real simulation over 361 aim angles per board state.
///
/// The pipeline guarantees, for every arena below:
///
///   * every target is destructible from a full board — no impossible target;
///   * the arena CANNOT be cleared in a single shot (arenas 2 and 7 originally
///     could, and had their requirements raised automatically until they could
///     not — that degenerate "spray it flat" line is the failure mode this whole
///     mechanic has to be defended against);
///   * `shots` is a real greedy clearing line plus one spare, so the budget is
///     achievable rather than guessed;
///   * star thresholds are 50% / 72% / 90% of a score actually achieved by that
///     line.
///
/// What no solver can tell us: whether these are FUN, and whether a human finds
/// the shots that an exhaustive angle sweep finds. That still needs playtesting.
///
/// To change anything here, edit `tools/solver/campaign.js` and re-run
/// `node campaign.js` — do not hand-edit the tuned numbers, they will be wrong.
/// Editing `kMaxBanks` or `kMinAimUp` invalidates the whole file.
const List<ArenaSpec> kArenas = <ArenaSpec>[
  // ---------------------------------------------------------------
  // Chương 1 — Học luật dội
  // ---------------------------------------------------------------
  ArenaSpec(
    id: 1,
    name: 'Bắn thẳng không tính',
    nameEn: 'Straight shots don\'t count',
    hint: 'Bắn thẳng thì chúng nó cười. Phải dội tường trước đã!',
    hintEn: 'Shoot one head-on and it laughs. Bank off a wall first!',
    shots: 3,
    targets: <TargetSpec>[
      TargetSpec(V2(50, 104), 1, palette: 0),
      TargetSpec(V2(22, 44), 1, palette: 1),
      TargetSpec(V2(78, 44), 1, palette: 2),
    ],
    blocks: <BlockSpec>[
      BlockSpec(40, 60, 60, 68),
    ],
    starThresholds: <int>[750, 1100, 1350],
  ),
  ArenaSpec(
    id: 2,
    name: 'Ba đứa trên cao',
    nameEn: 'Three up top',
    hint: 'Không có vật cản. Chỉ có tường và góc bắn của bạn.',
    hintEn: 'No obstacles. Just walls and your angle.',
    shots: 3,
    targets: <TargetSpec>[
      TargetSpec(V2(20, 36), 3, palette: 1),
      TargetSpec(V2(50, 28), 2, palette: 2),
      TargetSpec(V2(80, 36), 3, palette: 3),
    ],
    starThresholds: <int>[750, 1100, 1350],
  ),
  ArenaSpec(
    id: 3,
    name: 'Sát tường',
    nameEn: 'Hugging the wall',
    hint: 'Đứa sát tường khó ăn hơn đứa giữa sân.',
    hintEn: 'The ones against the wall are harder than the ones in the middle.',
    shots: 3,
    targets: <TargetSpec>[
      TargetSpec(V2(11, 112), 2, palette: 0),
      TargetSpec(V2(89, 112), 2, palette: 1),
      TargetSpec(V2(50, 40), 1, palette: 2),
    ],
    starThresholds: <int>[550, 800, 1000],
  ),
  ArenaSpec(
    id: 4,
    name: 'Hình thoi',
    nameEn: 'Diamond',
    hint: 'Một cú đi xuyên được mấy đứa?',
    hintEn: 'How many can one shot punch through?',
    shots: 3,
    targets: <TargetSpec>[
      TargetSpec(V2(50, 30), 1, palette: 0),
      TargetSpec(V2(28, 60), 2, palette: 1),
      TargetSpec(V2(72, 60), 2, palette: 2),
      TargetSpec(V2(50, 92), 1, palette: 3),
    ],
    blocks: <BlockSpec>[
      BlockSpec(44, 44, 56, 50),
    ],
    starThresholds: <int>[850, 1200, 1550],
  ),
  ArenaSpec(
    id: 5,
    name: 'Sau cây cột',
    nameEn: 'Behind the pillar',
    hint: 'Cột giữa sân không cho bạn đi đường thẳng.',
    hintEn: 'The pillar takes the straight line away from you.',
    shots: 3,
    targets: <TargetSpec>[
      TargetSpec(V2(26, 52), 2, palette: 0),
      TargetSpec(V2(74, 52), 2, palette: 1),
      TargetSpec(V2(50, 22), 1, palette: 2),
    ],
    blocks: <BlockSpec>[
      BlockSpec(44, 66, 56, 118),
    ],
    starThresholds: <int>[650, 950, 1150],
  ),
  // ---------------------------------------------------------------
  // Chương 2 — Kệ và hốc
  // ---------------------------------------------------------------
  ArenaSpec(
    id: 6,
    name: 'Ngóc ngách',
    nameEn: 'Pockets',
    hint: 'Mấy đứa trong hốc chỉ ăn cú dội từ trên xuống thôi.',
    hintEn: 'The ones in the alcoves only take a bank from above.',
    shots: 4,
    targets: <TargetSpec>[
      TargetSpec(V2(50, 100), 1, palette: 0),
      TargetSpec(V2(15, 54), 2, palette: 1),
      TargetSpec(V2(85, 54), 2, palette: 2),
      TargetSpec(V2(50, 24), 3, palette: 3),
    ],
    blocks: <BlockSpec>[
      BlockSpec(0, 66, 30, 73),
      BlockSpec(70, 66, 100, 73),
    ],
    deflectors: <DeflectorSpec>[
      DeflectorSpec(V2(40, 38), V2(60, 38)),
    ],
    starThresholds: <int>[950, 1350, 1700],
  ),
  ArenaSpec(
    id: 7,
    name: 'Mái che',
    nameEn: 'The awning',
    hint: 'Có mái thì đi vòng, đừng đi thẳng.',
    hintEn: 'There is a roof. Go around it.',
    shots: 3,
    targets: <TargetSpec>[
      TargetSpec(V2(24, 30), 2, palette: 0),
      TargetSpec(V2(76, 30), 2, palette: 1),
      TargetSpec(V2(50, 78), 2, palette: 2),
    ],
    blocks: <BlockSpec>[
      BlockSpec(32, 46, 68, 54),
    ],
    starThresholds: <int>[700, 1000, 1250],
  ),
  ArenaSpec(
    id: 8,
    name: 'Bậc thang',
    nameEn: 'Staircase',
    hint: 'Bậc thang bên trái là tường phụ, dùng nó đi.',
    hintEn: 'Those steps on the left are extra walls. Use them.',
    shots: 3,
    targets: <TargetSpec>[
      TargetSpec(V2(80, 100), 2, palette: 0),
      TargetSpec(V2(80, 62), 3, palette: 1),
      TargetSpec(V2(78, 26), 2, palette: 2),
    ],
    blocks: <BlockSpec>[
      BlockSpec(0, 112, 30, 119),
      BlockSpec(0, 74, 22, 81),
      BlockSpec(0, 36, 14, 43),
    ],
    starThresholds: <int>[700, 1000, 1250],
  ),
  ArenaSpec(
    id: 9,
    name: 'Hai cái hốc',
    nameEn: 'Two nooks',
    hint: 'Hai bên là hốc. Giữa là đường vào.',
    hintEn: 'Nooks on both sides. The middle is the way in.',
    shots: 3,
    targets: <TargetSpec>[
      TargetSpec(V2(14, 90), 2, palette: 0),
      TargetSpec(V2(86, 90), 2, palette: 1),
      TargetSpec(V2(50, 34), 2, palette: 2),
      TargetSpec(V2(50, 118), 1, palette: 3),
    ],
    blocks: <BlockSpec>[
      BlockSpec(0, 104, 28, 110),
      BlockSpec(72, 104, 100, 110),
      BlockSpec(40, 60, 60, 66),
    ],
    starThresholds: <int>[900, 1300, 1600],
  ),
  ArenaSpec(
    id: 10,
    name: 'Kẹp giữa',
    nameEn: 'Squeezed',
    hint: 'Khe giữa hai cột hẹp hơn bạn tưởng.',
    hintEn: 'The gap between the pillars is tighter than it looks.',
    shots: 4,
    targets: <TargetSpec>[
      TargetSpec(V2(50, 42), 3, palette: 0),
      TargetSpec(V2(20, 100), 2, palette: 1),
      TargetSpec(V2(80, 100), 2, palette: 2),
    ],
    blocks: <BlockSpec>[
      BlockSpec(32, 60, 40, 120),
      BlockSpec(60, 60, 68, 120),
    ],
    starThresholds: <int>[750, 1100, 1350],
  ),
  // ---------------------------------------------------------------
  // Chương 3 — Zig-zag
  // ---------------------------------------------------------------
  ArenaSpec(
    id: 11,
    name: 'Chuỗi dội',
    nameEn: 'Bank chain',
    hint: 'Càng dội càng nhân điểm. Một cú ăn hết bốn đứa được không?',
    hintEn: 'More banks, bigger multiplier. Can one shot take all four?',
    shots: 3,
    targets: <TargetSpec>[
      TargetSpec(V2(14, 118), 1, palette: 0),
      TargetSpec(V2(86, 96), 2, palette: 1),
      TargetSpec(V2(14, 74), 3, palette: 2),
      TargetSpec(V2(86, 52), 4, palette: 3),
    ],
    blocks: <BlockSpec>[
      BlockSpec(46, 84, 54, 112),
    ],
    starThresholds: <int>[800, 1150, 1450],
  ),
  ArenaSpec(
    id: 12,
    name: 'Leo thang',
    nameEn: 'Climbing',
    hint: 'Đi zig-zag lên. Đừng tham đứa trên cùng ngay.',
    hintEn: 'Zig-zag your way up. Do not grab for the top one first.',
    shots: 4,
    targets: <TargetSpec>[
      TargetSpec(V2(12, 108), 1, palette: 0),
      TargetSpec(V2(88, 82), 2, palette: 1),
      TargetSpec(V2(12, 56), 3, palette: 2),
      TargetSpec(V2(88, 30), 4, palette: 3),
      TargetSpec(V2(50, 128), 1, palette: 0),
    ],
    starThresholds: <int>[1150, 1650, 2050],
  ),
  ArenaSpec(
    id: 13,
    name: 'Hành lang',
    nameEn: 'The corridor',
    hint: 'Hành lang hẹp: bi vào được thì dội rất nhanh.',
    hintEn: 'A narrow corridor: once the ball is in, banks come fast.',
    shots: 4,
    targets: <TargetSpec>[
      TargetSpec(V2(50, 24), 3, palette: 0),
      TargetSpec(V2(50, 56), 2, palette: 1),
      TargetSpec(V2(18, 122), 1, palette: 2),
      TargetSpec(V2(82, 122), 1, palette: 3),
    ],
    blocks: <BlockSpec>[
      BlockSpec(34, 74, 42, 132),
      BlockSpec(58, 74, 66, 132),
    ],
    starThresholds: <int>[900, 1300, 1600],
  ),
  ArenaSpec(
    id: 14,
    name: 'Dán tường',
    nameEn: 'Wallflowers',
    hint: 'Cả bốn đứa đều dán tường. Vui đấy.',
    hintEn: 'All four are stuck to the walls. Have fun.',
    shots: 3,
    targets: <TargetSpec>[
      TargetSpec(V2(10, 120), 2, palette: 0),
      TargetSpec(V2(10, 60), 3, palette: 1),
      TargetSpec(V2(90, 120), 2, palette: 2),
      TargetSpec(V2(90, 60), 3, palette: 3),
    ],
    blocks: <BlockSpec>[
      BlockSpec(42, 40, 58, 130),
    ],
    starThresholds: <int>[900, 1300, 1600],
  ),
  ArenaSpec(
    id: 15,
    name: 'Chữ thập',
    nameEn: 'The cross',
    hint: 'Bốn góc, một cây thập ở giữa.',
    hintEn: 'Four corners, one cross in the middle.',
    shots: 3,
    targets: <TargetSpec>[
      TargetSpec(V2(18, 40), 2, palette: 0),
      TargetSpec(V2(82, 40), 2, palette: 1),
      TargetSpec(V2(18, 110), 2, palette: 2),
      TargetSpec(V2(82, 110), 2, palette: 3),
    ],
    blocks: <BlockSpec>[
      BlockSpec(44, 44, 56, 106),
      BlockSpec(28, 70, 72, 80),
    ],
    starThresholds: <int>[900, 1300, 1600],
  ),
  // ---------------------------------------------------------------
  // Chương 4 — Vật cản chéo
  // ---------------------------------------------------------------
  ArenaSpec(
    id: 16,
    name: 'Chéo giữa sân',
    nameEn: 'Diagonal',
    hint: 'Vật cản chéo đổi hướng bi kiểu khác tường.',
    hintEn: 'A diagonal bumper turns the ball differently from a wall.',
    shots: 3,
    targets: <TargetSpec>[
      TargetSpec(V2(20, 44), 2, palette: 0),
      TargetSpec(V2(80, 44), 2, palette: 1),
      TargetSpec(V2(50, 110), 1, palette: 2),
    ],
    deflectors: <DeflectorSpec>[
      DeflectorSpec(V2(34, 84), V2(66, 68)),
    ],
    starThresholds: <int>[750, 1100, 1350],
  ),
  ArenaSpec(
    id: 17,
    name: 'Cái phễu',
    nameEn: 'The funnel',
    hint: 'Phễu đẩy bi ra hai bên. Đừng chống lại nó.',
    hintEn: 'The funnel pushes the ball out to the sides. Do not fight it.',
    shots: 3,
    targets: <TargetSpec>[
      TargetSpec(V2(14, 62), 3, palette: 0),
      TargetSpec(V2(86, 62), 3, palette: 1),
      TargetSpec(V2(50, 26), 2, palette: 2),
    ],
    deflectors: <DeflectorSpec>[
      DeflectorSpec(V2(30, 96), V2(48, 116)),
      DeflectorSpec(V2(70, 96), V2(52, 116)),
    ],
    starThresholds: <int>[750, 1100, 1350],
  ),
  ArenaSpec(
    id: 18,
    name: 'Nóc nhà',
    nameEn: 'The rooftop',
    hint: 'Đứa trên nóc chỉ vào được từ bên sườn.',
    hintEn: 'The one on the roof can only be entered from a flank.',
    shots: 4,
    targets: <TargetSpec>[
      TargetSpec(V2(50, 20), 3, palette: 0),
      TargetSpec(V2(22, 74), 2, palette: 1),
      TargetSpec(V2(78, 74), 2, palette: 2),
      TargetSpec(V2(50, 116), 1, palette: 3),
    ],
    blocks: <BlockSpec>[
      BlockSpec(30, 34, 70, 40),
    ],
    deflectors: <DeflectorSpec>[
      DeflectorSpec(V2(12, 52), V2(30, 40)),
      DeflectorSpec(V2(88, 52), V2(70, 40)),
    ],
    starThresholds: <int>[950, 1350, 1700],
  ),
  ArenaSpec(
    id: 19,
    name: 'Hai lưỡi dao',
    nameEn: 'Two blades',
    hint: 'Hai lưỡi chéo hai bên. Bi sẽ đi lối bạn không định.',
    hintEn: 'Two blades on the flanks. The ball goes where you did not plan.',
    shots: 4,
    targets: <TargetSpec>[
      TargetSpec(V2(50, 34), 3, palette: 0),
      TargetSpec(V2(16, 108), 2, palette: 1),
      TargetSpec(V2(84, 108), 2, palette: 2),
      TargetSpec(V2(50, 74), 2, palette: 3),
    ],
    deflectors: <DeflectorSpec>[
      DeflectorSpec(V2(6, 88), V2(34, 62)),
      DeflectorSpec(V2(94, 88), V2(66, 62)),
    ],
    starThresholds: <int>[800, 1150, 1450],
  ),
  ArenaSpec(
    id: 20,
    name: 'Bừa hết cỡ',
    nameEn: 'Full send',
    hint: 'Tất cả cùng lúc. Bắn bừa đúng chỗ đi.',
    hintEn: 'Everything at once. Be reckless in the right place.',
    shots: 5,
    targets: <TargetSpec>[
      TargetSpec(V2(50, 18), 4, palette: 0),
      TargetSpec(V2(14, 52), 3, palette: 1),
      TargetSpec(V2(86, 52), 3, palette: 2),
      TargetSpec(V2(26, 106), 2, palette: 3),
      TargetSpec(V2(74, 106), 2, palette: 0),
      TargetSpec(V2(50, 128), 1, palette: 1),
    ],
    blocks: <BlockSpec>[
      BlockSpec(38, 34, 62, 40),
      BlockSpec(44, 70, 56, 92),
    ],
    deflectors: <DeflectorSpec>[
      DeflectorSpec(V2(8, 78), V2(30, 62)),
      DeflectorSpec(V2(92, 78), V2(70, 62)),
    ],
    starThresholds: <int>[1300, 1850, 2350],
  ),
];

int starsFor(ArenaSpec arena, int score) {
  int stars = 0;
  for (final int threshold in arena.starThresholds) {
    if (score >= threshold) stars++;
  }
  return stars;
}
