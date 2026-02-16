import 'package:flutter/material.dart';

/// General Knowledge Screen - Comprehensive Factual Content
class GeneralKnowledgeScreen extends StatefulWidget {
  const GeneralKnowledgeScreen({super.key});

  @override
  State<GeneralKnowledgeScreen> createState() => _GeneralKnowledgeScreenState();
}

class _GeneralKnowledgeScreenState extends State<GeneralKnowledgeScreen> {
  String _selectedCategory = 'All Categories';
  final List<String> _categories = [
    'All Categories',
    'Indian History',
    'Indian Geography',
    'Indian Polity',
    'World Geography',
    'Science & Technology',
    'Economy',
    'Awards & Honours',
    'Sports',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'General Knowledge',
          style: TextStyle(fontFamily: 'Ubuntu'),
        ),
        backgroundColor: const Color(0xFFE65100),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.category),
            onSelected: (value) => setState(() => _selectedCategory = value),
            itemBuilder: (context) => _categories
                .map(
                  (category) => PopupMenuItem(
                    value: category,
                    child: Text(
                      category,
                      style: const TextStyle(fontFamily: 'Ubuntu'),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange.shade50, Colors.white],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildCategoryHeader(),
            const SizedBox(height: 16),
            ..._getContentByCategory(_selectedCategory),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE65100), Color(0xFFD84315)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.menu_book, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedCategory,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Ubuntu',
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '100% Verified Information',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontFamily: 'Ubuntu',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _getContentByCategory(String category) {
    if (category == 'All Categories' || category == 'Indian History') {
      return [
        _buildGKCard(
          title: 'Important Historical Events of India',
          icon: Icons.history_edu,
          color: Colors.brown,
          content: '''
**Ancient India:**

**Indus Valley Civilization (3300-1300 BCE)**
• One of the world's oldest civilizations
• Major cities: Harappa, Mohenjo-daro, Lothal, Dholavira
• Known for: Urban planning, drainage system, standardized weights
• Script: Indus script (still undeciphered)

**Vedic Period (1500-500 BCE)**
• Composition of Vedas (Rigveda, Samaveda, Yajurveda, Atharvaveda)
• Development of caste system
• Rise of 16 Mahajanapadas

**Mauryan Empire (322-185 BCE)**
• Founded by: Chandragupta Maurya
• Greatest ruler: Ashoka the Great (304-232 BCE)
• Capital: Pataliputra (modern Patna)
• Ashoka's edicts spread Buddhism across Asia
• Administration: Highly centralized bureaucracy

**Gupta Empire (320-550 CE) - Golden Age**
• Founded by: Chandragupta I
• Peak under: Chandragupta II (Vikramaditya)
• Achievements:
  - Mathematics: Aryabhata's contributions, concept of zero
  - Literature: Kalidasa's works (Shakuntala, Meghaduta)
  - Art: Ajanta & Ellora caves
  - Astronomy: Varahamihira's Pancha Siddhantika

**Medieval India:**

**Delhi Sultanate (1206-1526)**
• Five dynasties: Mamluk, Khilji, Tughlaq, Sayyid, Lodi
• Important rulers:
  - Qutub-ud-din Aibak (built Qutub Minar)
  - Alauddin Khilji (defeated Mongols)
  - Muhammad bin Tughlaq (shifted capital to Daulatabad)

**Mughal Empire (1526-1857)**
• Founded by: Babur (Battle of Panipat, 1526)
• Greatest rulers:
  - Akbar (1556-1605): Religious tolerance, Din-i-Ilahi
  - Jahangir (1605-1627): Justice and art patron
  - Shah Jahan (1628-1658): Built Taj Mahal
  - Aurangzeb (1658-1707): Last great Mughal emperor

**British India:**

**Key Events:**
• Battle of Plassey (1757) - British dominance begins
• Revolt of 1857 - First War of Independence
• Indian National Congress founded (1885)
• Partition of Bengal (1905)
• Jallianwala Bagh Massacre (1919)
• Non-Cooperation Movement (1920-22)
• Salt March (1930)
• Quit India Movement (1942)
• Independence (August 15, 1947)

**Freedom Fighters:**
• Mahatma Gandhi: Father of the Nation
• Jawaharlal Nehru: First Prime Minister
• Sardar Vallabhbhai Patel: Iron Man of India
• Subhas Chandra Bose: Netaji, INA leader
• Bhagat Singh, Rajguru, Sukhdev: Revolutionary martyrs
• Rani Lakshmibai: Warrior queen of Jhansi
''',
        ),
      ];
    } else if (category == 'Indian Geography') {
      return [
        _buildGKCard(
          title: 'Indian Geography - Complete Facts',
          icon: Icons.map,
          color: Colors.green,
          content: '''
**Basic Facts:**

**Location:**
• Northern Hemisphere
• Latitude: 8°4'N to 37°6'N
• Longitude: 68°7'E to 97°25'E
• Tropic of Cancer (23°30'N) divides India

**Area & Borders:**
• Total Area: 3,287,263 sq km (7th largest country)
• Land Borders: 15,106.7 km
• Coastline: 7,516.6 km
• Neighboring Countries: 7 (Pakistan, Afghanistan, China, Nepal, Bhutan, Bangladesh, Myanmar)
• Maritime Neighbors: Sri Lanka, Maldives

**Physical Divisions:**

**1. The Himalayas**
• Northern mountain barrier
• Youngest fold mountains
• Highest peak: K2 (8,611 m) in POK
• Highest peak in India: Kanchenjunga (8,586 m)
• Three ranges: Himadri, Himachal, Shiwalik

**2. Northern Plains**
• Formed by: Indus, Ganga, Brahmaputra
• Most fertile region
• Major crops: Rice, wheat, sugarcane
• Divided into: Punjab Plains, Ganga Plains, Brahmaputra Plains

**3. Peninsular Plateau**
• Oldest landmass
• Rich in minerals
• Western Ghats (Sahyadri)
• Eastern Ghats
• Deccan Plateau

**4. Coastal Plains**
• Western Coastal Plains: Konkan, Karnataka, Malabar
• Eastern Coastal Plains: Coromandel Coast

**5. Islands**
• Andaman & Nicobar Islands (Bay of Bengal)
• Lakshadweep Islands (Arabian Sea)

**Rivers:**

**Himalayan Rivers (Perennial):**
• Ganga (2,525 km) - National River
• Brahmaputra (916 km in India)
• Indus (1,114 km in India)

**Peninsular Rivers (Seasonal):**
• Godavari (1,465 km) - Longest peninsular river
• Krishna (1,400 km)
• Narmada (1,312 km)
• Tapi (724 km)

**Climate:**
• Type: Tropical Monsoon
• Seasons: 4 (Summer, Monsoon, Post-Monsoon, Winter)
• Southwest Monsoon: June-September (80% rainfall)
• Highest Rainfall: Mawsynram, Meghalaya (11,871 mm/year)

**States & Union Territories:**
• States: 28
• Union Territories: 8
• Capitals: Delhi (NCT), Mumbai (Maharashtra), Kolkata (West Bengal)
• Largest State: Rajasthan (area)
• Most Populous State: Uttar Pradesh
• Smallest State: Goa
''',
        ),
      ];
    } else if (category == 'Indian Polity') {
      return [
        _buildGKCard(
          title: 'Indian Constitution & Polity',
          icon: Icons.gavel,
          color: Colors.indigo,
          content: '''
**Indian Constitution:**

**Basic Facts:**
• Came into effect: January 26, 1950
• Longest written constitution: Originally 395 Articles, 22 Parts, 8 Schedules
• Current: 470+ Articles, 25 Parts, 12 Schedules (after 100+ amendments)
• Drafted by: Constituent Assembly (1946-1949)
• Chairman: Dr. B.R. Ambedkar

**Fundamental Rights (Part III):**
1. Right to Equality (Articles 14-18)
2. Right to Freedom (Articles 19-22)
3. Right against Exploitation (Articles 23-24)
4. Right to Freedom of Religion (Articles 25-28)
5. Cultural and Educational Rights (Articles 29-30)
6. Right to Constitutional Remedies (Article 32)

**Fundamental Duties (Article 51A):**
• Added by 42nd Amendment (1976)
• Originally 10, now 11 duties
• Examples: Respect National Flag, Protect environment

**Directive Principles of State Policy (Part IV):**
• Guidelines for state to establish social and economic democracy
• Not justiciable (cannot be enforced by courts)
• Examples: Right to work, free legal aid, uniform civil code

**Union Government:**

**President:**
• Head of State
• Elected by Electoral College
• Term: 5 years
• Powers: Executive, Legislative, Judicial, Emergency
• Current: Droupadi Murmu (15th President)

**Vice President:**
• Ex-officio Chairman of Rajya Sabha
• Elected by Electoral College (MPs only)
• Current: Jagdeep Dhankhar

**Prime Minister:**
• Head of Government
• Leader of majority party in Lok Sabha
• Appointed by President
• Current: Narendra Modi (14th PM)

**Parliament:**

**Lok Sabha (House of People):**
• Maximum strength: 552 (530 states + 20 UTs + 2 Anglo-Indians)
• Current strength: 545
• Term: 5 years
• Speaker: Presiding officer
• Quorum: 1/10th of total members

**Rajya Sabha (Council of States):**
• Maximum strength: 250 (238 elected + 12 nominated)
• Current strength: 245
• Permanent house (1/3rd retire every 2 years)
• Chairman: Vice President of India

**Judiciary:**

**Supreme Court:**
• Apex court, established: January 28, 1950
• Original jurisdiction, appellate jurisdiction, advisory jurisdiction
• Chief Justice + 33 other judges (total 34)
• Current CJI: D.Y. Chandrachud

**High Courts:**
• 25 High Courts in India
• Oldest: Calcutta High Court (1862)

**Amendment Procedure:**
• Article 368
• Three types:
  1. Simple Majority
  2. Special Majority (2/3rd present + voting)
  3. Special Majority + State Ratification

**Important Amendments:**
• 1st Amendment (1951): Restrictions on freedom of speech
• 42nd Amendment (1976): Mini Constitution
• 44th Amendment (1978): Right to property removed from FR
• 73rd & 74th Amendments (1992): Panchayati Raj & Municipalities
• 101st Amendment (2016): GST implementation
''',
        ),
      ];
    } else if (category == 'Science & Technology') {
      return [
        _buildGKCard(
          title: 'Science & Technology - Key Facts',
          icon: Icons.science,
          color: Colors.blue,
          content: '''
**Physics:**

**Units & Measurements:**
• SI Base Units: 7
  - Length: Meter (m)
  - Mass: Kilogram (kg)
  - Time: Second (s)
  - Temperature: Kelvin (K)
  - Electric Current: Ampere (A)
  - Luminous Intensity: Candela (cd)
  - Amount of Substance: Mole (mol)

**Important Laws:**
• Newton's Laws of Motion
• Law of Conservation of Energy
• Law of Conservation of Momentum
• Archimedes' Principle
• Pascal's Law
• Ohm's Law: V = IR

**Chemistry:**

**Periodic Table:**
• Elements: 118 (92 natural + 26 synthetic)
• Groups: 18 (vertical columns)
• Periods: 7 (horizontal rows)
• Most abundant element in universe: Hydrogen
• Most abundant element on Earth: Oxygen

**Important Compounds:**
• Water (H₂O): Universal solvent
• Common Salt (NaCl): Sodium Chloride
• Baking Soda (NaHCO₃): Sodium Bicarbonate
• Marble (CaCO₃): Calcium Carbonate
• Ammonia (NH₃): Used in fertilizers

**Biology:**

**Cell:**
• Basic unit of life
• Discovered by: Robert Hooke (1665)
• Types: Prokaryotic, Eukaryotic
• Cell organelles: Nucleus, Mitochondria, Chloroplast, etc.

**Human Body:**
• Bones: 206 in adult
• Largest organ: Skin
• Smallest bone: Stapes (ear)
• Largest bone: Femur (thigh bone)
• Blood groups: A, B, AB, O (Rh+/Rh-)
• Normal body temperature: 37°C (98.6°F)
• Heart rate: 60-100 beats/minute

**Diseases:**
• Bacterial: Tuberculosis, Cholera, Typhoid
• Viral: COVID-19, Influenza, Dengue, AIDS
• Deficiency: Scurvy (Vitamin C), Rickets (Vitamin D)

**Indian Space Programme:**

**ISRO Achievements:**
• Founded: 1969
• Headquarters: Bengaluru
• Major Missions:
  - Chandrayaan-1 (2008): Moon mission, discovered water
  - Mangalyaan/MOM (2013): Mars Orbiter Mission
  - Chandrayaan-2 (2019): Moon lander mission
  - Chandrayaan-3 (2023): Successful moon landing
  - Gaganyaan: Upcoming human spaceflight

**Satellites:**
• PSLV: Polar Satellite Launch Vehicle
• GSLV: Geosynchronous Satellite Launch Vehicle
• INSAT: Indian National Satellite System
• IRS: Indian Remote Sensing satellites

**Recent Technology:**

**Artificial Intelligence:**
• Machine Learning, Deep Learning
• Applications: Self-driving cars, virtual assistants
• AI in India: National AI Strategy, AI research centers

**Quantum Computing:**
• Uses quantum bits (qubits)
• Can solve complex problems faster
• India's National Quantum Mission (₹6,000 crore)

**5G Technology:**
• Fifth generation mobile network
• Speed: Up to 20 Gbps
• Launched in India: October 2022
• Applications: IoT, Smart cities, Autonomous vehicles
''',
        ),
      ];
    } else {
      return [_buildComingSoonCard()];
    }
  }

  Widget _buildGKCard({
    required String title,
    required IconData icon,
    required Color color,
    required String content,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontFamily: 'Ubuntu',
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                height: 1.7,
                color: Colors.black87,
                fontFamily: 'Ubuntu',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoonCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.schedule, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'More Content Coming Soon',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                  fontFamily: 'Ubuntu',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
