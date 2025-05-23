
typedef UnitDataMap = Map<String, UnitData>;

class UnitData {
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

  const UnitData({
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
}

const unitCatalog = <String, UnitData>{
  'infantry': UnitData(
    id: 'infantry', name: 'Infante', hp: 100, atk: 20, def: 15, speed: 6, range: 1,
    accuracy: 85, critRate: 5, critDamage: 150, evasion: 5, capacity: 10,
    costWood: 50, costStone: 20, costFood: 30, trainTimeSecs: 40,
  ),
  'archer': UnitData(
    id: 'archer', name: 'Arquero', hp: 70, atk: 30, def: 5, speed: 5, range: 5,
    accuracy: 90, critRate: 10, critDamage: 175, evasion: 10, capacity: 8,
    costWood: 80, costStone: 10, costFood: 40, trainTimeSecs: 45,
  ),
  'cavalry': UnitData(
    id: 'cavalry', name: 'Caballero', hp: 140, atk: 35, def: 25, speed: 8, range: 1,
    accuracy: 80, critRate: 7, critDamage: 160, evasion: 6, capacity: 15,
    costWood: 100, costStone: 50, costFood: 60, trainTimeSecs: 60,
  ),
  'lancer': UnitData(
    id: 'lancer', name: 'Lancero', hp: 110, atk: 25, def: 18, speed: 6, range: 2,
    accuracy: 87, critRate: 8, critDamage: 160, evasion: 7, capacity: 12,
    costWood: 70, costStone: 30, costFood: 50, trainTimeSecs: 50,
  ),
  'mage': UnitData(
    id: 'mage', name: 'Mago de Batalla', hp: 60, atk: 45, def: 8, speed: 4, range: 6,
    accuracy: 88, critRate: 20, critDamage: 200, evasion: 12, capacity: 5,
    costWood: 120, costStone: 20, costFood: 80, trainTimeSecs: 70,
  ),
  'knight_valiar': UnitData(
    id: 'knight_valiar', name: 'Caballero de Valiar', requiredRace: 'human',
    hp: 160, atk: 40, def: 30, speed: 7, range: 1,
    accuracy: 82, critRate: 10, critDamage: 160, evasion: 8, capacity: 18,
    costWood: 200, costStone: 100, costFood: 150, trainTimeSecs: 80,
  ),
  'archer_luna_velo': UnitData(
    id: 'archer_luna_velo', name: 'Arquera Luna-Velo', requiredRace: 'elf',
    hp: 75, atk: 35, def: 10, speed: 6, range: 6,
    accuracy: 93, critRate: 15, critDamage: 185, evasion: 14, capacity: 9,
    costWood: 150, costStone: 50, costFood: 150, trainTimeSecs: 75,
  ),
  'hammer_ferro': UnitData(
    id: 'hammer_ferro', name: 'Martillo de Roca', requiredRace: 'dwarf',
    hp: 180, atk: 30, def: 35, speed: 4, range: 1,
    accuracy: 78, critRate: 5, critDamage: 150, evasion: 4, capacity: 20,
    costWood: 100, costStone: 150, costFood: 150, trainTimeSecs: 90,
  ),
  'automaton_arcane': UnitData(
    id: 'automaton_arcane', name: 'Autómata Arcano', requiredRace: 'arcanian',
    hp: 120, atk: 50, def: 20, speed: 5, range: 3,
    accuracy: 85, critRate: 12, critDamage: 170, evasion: 9, capacity: 7,
    costWood: 150, costStone: 200, costFood: 100, trainTimeSecs: 100,
  ),
  'guardian_drake': UnitData(
    id: 'guardian_drake', name: 'Guardián Escama-Fuego', requiredRace: 'drakari',
    hp: 200, atk: 45, def: 40, speed: 6, range: 2,
    accuracy: 88, critRate: 18, critDamage: 190, evasion: 10, capacity: 16,
    costWood: 150, costStone: 200, costFood: 150, trainTimeSecs: 110,
  ),
};
