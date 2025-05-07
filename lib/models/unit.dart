// lib/models/unit.dart

class Unit {
  final String id;
  final String name;
  final String? requiredRace;
  final int hp;
  final int atk;
  final int def;
  final int speed;
  final int range;
  final int accuracy;
  final int critRate;
  final int critDamage;
  final int evasion;
  final int capacity;
  final int costWood;
  final int costStone;
  final int costFood;
  final int trainTimeSecs;

  Unit({
    required this.id,
    required this.name,
    this.requiredRace,
    required this.hp,
    required this.atk,
    required this.def,
    required this.speed,
    required this.range,
    required this.accuracy,
    required this.critRate,
    required this.critDamage,
    required this.evasion,
    required this.capacity,
    required this.costWood,
    required this.costStone,
    required this.costFood,
    required this.trainTimeSecs,
  });

  factory Unit.fromJson(Map<String, dynamic> j) => Unit(
        id:             j['id']           as String,
        name:           j['name']         as String,
        requiredRace:   j['requiredRace'] as String?,
        hp:             j['hp']           as int,
        atk:            j['atk']          as int,
        def:            j['def']          as int,
        speed:          j['speed']        as int,
        range:          j['range']        as int,
        accuracy:       j['accuracy']     as int,
        critRate:       j['critRate']     as int,
        critDamage:     j['critDamage']   as int,
        evasion:        j['evasion']      as int,
        capacity:       j['capacity']     as int,
        costWood:       j['costWood']     as int,
        costStone:      j['costStone']    as int,
        costFood:       j['costFood']     as int,
        trainTimeSecs:  j['trainTimeSecs']as int,
      );
}
