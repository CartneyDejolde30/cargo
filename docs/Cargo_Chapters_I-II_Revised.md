# CarGO Thesis — Revised Chapter I & II
> Revision Notes: All 8 flow recommendations applied. Changed sections are marked [REVISED].

---

# Chapter I
## INTRODUCTION

This chapter presents the background of the study, project objectives, significance of the study, conceptual framework, scope and limitation of the study, and the definition of terms.

---

## Background of the Study

Consumer behavior and resource usage patterns have undergone significant transformation with the emergence of sharing economy platforms. The transportation industry has witnessed the proliferation of peer-to-peer marketplaces that enable private individuals to share assets through short-term rentals rather than relying on traditional corporate providers, as seen in platforms like Airbnb for accommodations and Uber or Lyft for rides (Fraiberger & Sundararajan, 2016). In transportation specifically, peer-to-peer carsharing enables private vehicle owners to make their cars available for temporary rental to other users, representing a departure from traditional ownership models toward access-oriented consumption.

Such arrangements help address a critical inefficiency: the majority of personal vehicles remain unused for over 90 percent of each day, while simultaneously removing the substantial initial investment burdens faced by conventional carsharing businesses (Peer-to-Peer Carsharing: Market Analysis and Potential Growth, 2011). Research findings indicate that carsharing services provide cost savings for substantial population segments while contributing to fewer privately-owned vehicles on roadways, leading to decreased emissions and reduced traffic congestion (Barbour et al., 2020).

Within the Philippine context, peer-to-peer vehicle sharing platforms encounter distinct circumstances and possibilities. Market analysis projects the country's car rental sector will expand from its current USD 682.27 million valuation in 2025 to USD 988.63 million by 2030, reflecting robust growth fueled by international visitor arrivals, digital economic expansion, and business-related transportation requirements (Mordor Intelligence, 2025).

[REVISED] The Philippine transportation environment exhibits dual characteristics: motorcycles serve as the predominant choice for daily urban travel owing to their economic advantages, fuel efficiency, and ability to navigate congested traffic, whereas automobiles fulfill family transportation and extended travel purposes. Despite this diversity in transportation needs, current peer-to-peer platforms and conventional rental agencies have not successfully integrated both vehicle categories into a single, technologically advanced system.

[REVISED] Conventional rental agencies encounter limitations in geographic expansion due to fleet acquisition expenses and concentrate operations near airports and metropolitan centers, resulting in inadequate service coverage for semi-urban regions (Mohd, 2012). Beyond geographic constraints, reliance on manual reservation systems and suboptimal fleet coordination creates additional barriers for both visitors and local populations. This is particularly evident in tourism destinations such as Siargao Island, where rental operations remain disjointed and inconsistent, leaving travelers without reliable access to vehicles (Golo & Encarnacion, 2024).

[REVISED] Cargo platform development responds to these identified gaps through a comprehensive peer-to-peer rental solution supporting multiple vehicle types. Differentiating itself from existing platforms that exclusively concentrate on automobiles or employ outdated technological frameworks, Cargo incorporates both cars and motorcycles within a singular mobile application developed using Flutter, providing optimal performance and compatibility across platforms. The platform employs multiple verification layers that combine government-issued identification validation with facial recognition technology to minimize fraudulent account creation—addressing a primary concern documented in peer-to-peer carsharing literature where roughly half of prospective users indicate apprehension regarding insurance coverage, liability issues, vehicle damage risks, and renter trustworthiness (Balles-Armet et al., 2014).

[REVISED] To further reinforce trust and accountability, Cargo implements real-time GPS tracking functionality throughout active rental periods, alleviating owner concerns about vehicle whereabouts and unauthorized usage. The platform's integration with GCash—which serves as the preferred financial transaction tool for 94% of Filipino users in everyday purchases (Capstone-Intel Corp., 2024)—facilitates secure digital payment processing without necessitating conventional banking relationships. Furthermore, Cargo's sophisticated multidimensional evaluation system assesses vehicle quality, owner responsiveness, and renter conduct, establishing trust through transparent feedback mechanisms that have demonstrated effectiveness in peer-to-peer marketplace environments (Barbour et al., 2020).

[REVISED] Empirical evidence suggests peer-to-peer carsharing participants are predominantly driven by financial incentives and opportunities to generate income from idle assets, with demographic characteristics such as income levels, educational attainment, age demographics, and gender composition significantly affecting willingness to participate (Wilhelms et al., 2017; Shaheen et al., 2018). Cargo's commission-oriented business framework addresses this motivation directly, establishing sustainable revenue generation while allowing vehicle proprietors to create supplementary income and enabling renters to obtain economical transportation alternatives. Given the progressive normalization of digital financial services across demographic groups (Domingo-Coronel, 2024), Cargo's deployment constitutes a strategically-timed initiative that advances resource optimization and economic prospects within Filipino urban and semi-urban areas.

---

## Objective of the Study

General and specific objectives were formulated from the gathered data then analyzed.

### General Objectives

The system aims to develop a user-friendly, secure, and efficient peer-to-peer multi-vehicle rental platform that enables vehicle owners (cars and motorcycles) to list their assets for rental and allows renters to access affordable, flexible transportation options through mobile technology. The system aims to enhance the overall rental experience by providing advanced identity verification, real-time GPS tracking, seamless GCash payment integration, comprehensive rating systems, and intuitive navigation for both vehicle owners and renters.

### Specific Objectives

Specifically, the system provides modules in terms of:

1.1 Authentication Module
1.2 Vehicle Management Module
1.3 Booking Module
1.4 Admin Module
1.5 Payment Module
1.6 Rating Module
1.7 GPS Tracking Module
1.8 Messaging Module

---

## Significance of the Study

The development of Cargo is beneficial to the following sectors:

Vehicle Owners (Car and Motorcycle Owners) — The proposed system can help vehicle owners monetize their idle vehicles by listing them on the platform, generating passive income while retaining ownership. The system provides tools for managing bookings and tracking earnings with minimal effort.

Renters (Users) — The proposed system provides a user-friendly platform that allows renters to access affordable transportation—cars or motorcycles—from their mobile devices, saving time and money compared to traditional rental agencies.

Community (Society) — The proposed system provides convenient transportation access through shared mobility, reducing traffic congestion while creating local economic opportunities.

---

## Conceptual Framework

[REVISED] The conceptual framework of the study is depicted in Figure 1, which illustrates the Input-Process-Output (IPO) model guiding the development of the Cargo platform. The Input component encompasses the data and user interactions entering the system, including vehicle listings, booking requests, payment submissions, GPS coordinates, and user credentials. The Process component represents the system's core operations—authentication, booking management, payment processing, real-time GPS tracking, and administrative oversight—carried out through the mobile application and web-based admin panel. The Output component reflects the results delivered to each stakeholder: confirmed bookings, real-time tracking data, digital receipts, payout summaries, and user ratings.

The researchers have incorporated all identified modules into both the mobile application and web-based administration platform, ensuring that all essential features are accessible to users based on their assigned roles. Each function is carefully designed to provide a seamless rental experience, allowing vehicle owners and renters to navigate the platform easily and efficiently. By clearly identifying and organizing these functions across the system's modules, Cargo helps users quickly understand how to use the platform to meet their transportation needs, facilitating a smooth and secure rental experience from vehicle listing through to payment and review.

Figure 1.0 Flow of the Study

---

## Scope and Limitations of the Study

### Scope of the Study

The Cargo platform is designed to provide a comprehensive peer-to-peer vehicle rental marketplace for users to rent cars and motorcycles conveniently from their mobile devices. The scope of the system includes:

1.1 Authentication Module:
Users register with government ID and selfie verification, then login using email and password with admin approval.

1.2 Vehicle Management Module:
Vehicle owners manage their car and motorcycle listings while renters browse, search, and view vehicle details.

1.3 Booking Module:
Facilitates booking requests, acceptance/decline workflow, trip management, and tracks booking history.

1.4 Payment Module:
Processes GCash payments, generates digital receipts, tracks earnings and payment history, and manages payouts.

1.5 Rating Module:
Enables post-trip ratings and reviews for owners and renters to build trust and improve service quality.

1.6 Admin Module:
Administrators verify users, approve listings, monitor bookings, resolve disputes, and generate platform reports.

---

### Limitation of the Study

The Cargo peer-to-peer vehicle rental platform has several limitations that may impact its functionality and user experience. The platform is implemented as a pilot program in a specific geographical area, restricting access for users outside the service region. The system requires stable internet connectivity, which may cause difficulties for users in areas with poor internet service, particularly affecting real-time features such as GPS tracking and messaging. Insurance and liability coverage is not provided by the platform, leaving responsibility with individual users to secure appropriate insurance. Payment processing is limited to GCash only, excluding users without GCash accounts. GPS tracking accuracy depends on device capabilities and environmental conditions. The system operates on XAMPP local hosting for development, meaning production-level scalability testing is beyond this project's scope. Customer support services may be limited during the pilot phase, with potential delays in addressing user concerns and resolving disputes. These limitations indicate areas for further improvement to enhance the service's reliability, security, and accessibility in future iterations.

---

## Definition of Terms

Admin Module — The module that allows administrators to verify users, approve listings, monitor bookings, resolve disputes, and generate platform reports.

Authentication Module — The module that handles user registration, login/logout, government ID verification, selfie validation, and admin approval workflows.

Booking Module — The module that facilitates booking requests, acceptance/decline workflows, trip management, status tracking, and booking history.

Car Owner — A registered user who owns automobiles and lists them on Cargo for peer-to-peer rental.

Flutter — An open-source mobile framework by Google that enables cross-platform app development for Android and iOS using a single codebase.

GCash — A mobile money service in the Philippines that enables cashless transactions including payments and money transfers without traditional bank accounts.

GPS Tracking — Technology that monitors and displays real-time vehicle location during active rentals using geographic coordinates from the renter's mobile device.

[REVISED: HTML removed — not referenced in any system module]

Motorcycle Owner — A registered user who owns motorcycles or scooters and lists them on Cargo for peer-to-peer rental.

MySQL — An open-source relational database management system that stores all Cargo platform data including users, vehicles, bookings, and payments.

Payment Module — The module that processes GCash transactions, generates digital receipts, tracks earnings and payment history, and manages payouts.

Peer-to-Peer (P2P) — A decentralized model where individuals directly transact with each other, enabling vehicle owners to rent their assets to renters.

PHP — A server-side scripting language used to create the backend API that processes requests from the mobile application and web admin panel.

Rating Module — The module that enables post-trip ratings and written reviews for owners and renters to build trust and improve service quality.

Renter — A registered user who searches for, books, and temporarily uses vehicles listed by owners for personal transportation needs.

Sharing Economy — An economic model emphasizing access over ownership, where individuals share underutilized assets through digital platforms.

UI — User Interface refers to the visual elements and interactive components users engage with in the Cargo mobile application.

UX — User Experience refers to the entire interaction users have with the Cargo platform, including ease of navigation and overall satisfaction.

Vehicle Management Module — The module that allows owners to manage their vehicle listings while enabling renters to browse, search, and view vehicle details.

XAMPP — A free, open-source local web server environment for development and testing that includes Apache, MySQL, PHP, and Perl.

---
---

# Chapter II
## REVIEW OF RELATED LITERATURE AND SYSTEMS

This chapter presents a brief overview of the evolution of technology, the significant impact of technology on transportation and shared mobility, a review of related literature, and a synthesis connecting prior studies to the development of the Cargo platform.

---

## Brief Overview of the Current Evolution of Technology

Mobile technology is now a vital aspect of everyday life, changing how individuals interact, perform their jobs, travel, and manage business activities. The sharing economy has emerged as a significant economic force in this generation, transforming conventional industries by offering consumers easy and accessible peer-to-peer marketplace platforms.

The rise of sharing economy platforms has empowered people to profit from underused assets from any location and at any moment, dismantling geographical obstacles and facilitating access to services that were once controlled by centralized companies (Fraiberger & Sundararajan, 2016). This change has been prompted by multiple factors, such as the extensive access to high-speed internet, progress in mobile technology, the growing acceptance of secure digital payment methods, and the normalization of exchanges between unfamiliar individuals enabled by trust mechanisms like identity verification and rating systems (Barbour et al., 2020).

The influence of mobile technology on travel behavior is also evident in how companies have adjusted to fulfill the changing demands of digital customers. Studies indicate that peer-to-peer platforms are increasingly focusing on developing strong mobile applications, intuitive interfaces, and secure authentication systems to engage and maintain users (Wilhelms et al., 2017). These initiatives involve providing multiple payment methods, safeguarding transaction security through identity checks, and establishing effective communication channels between service providers and customers. Additionally, mobile platforms have allowed people to engage in the sharing economy with lower overhead expenses than conventional businesses, enabling vehicle owners to earn revenue from unused assets, present competitive rates, and offer flexible rental options that conventional car rental companies struggle to match (Peer-to-Peer Carsharing: Market Analysis and Potential Growth, 2011).

[REVISED] The following sections examine specific studies and literature that directly inform Cargo's design, situating the platform within the broader research landscape on peer-to-peer vehicle sharing, consumer behavior, digital payment adoption, and local market conditions.

---

## Relevant Studies

### Peer-to-Peer Carsharing and Market Insights

As digital transformation reshapes transportation, peer-to-peer (P2P) vehicle sharing has gained attention for its role in modern mobility. Studies show that P2P carsharing offers cost savings, flexibility, and better vehicle utilization—addressing the problem of cars sitting idle most of the time. It is especially viable in low-density areas where traditional models struggle, though unclear policies and insurance rules remain barriers (Peer-to-Peer Carsharing: Market Analysis and Potential Growth, 2011).

---

### Consumer Participation and Trust

Research shows that around 25% of vehicle owners are willing to rent out their cars, mainly for financial gain. However, concerns about insurance, liability, and trust affect adoption. Platforms with strong identity verification, transparent rating systems, and reliable feedback mechanisms see higher participation (Barbour et al., 2020; Balles-Armet et al., 2014).

[REVISED] Addressing these concerns directly, Cargo implements government ID validation combined with facial recognition to authenticate users before they are approved by an administrator, reducing the risk of fraudulent accounts that deter owners from participating. In addition, Cargo's multidimensional post-trip rating system—which evaluates vehicle condition, owner responsiveness, and renter conduct—creates a transparent accountability layer that builds trust over time and encourages continued platform engagement from both user groups.

---

### Payment Technology Integration

[REVISED] Mobile payment systems like GCash have enabled financial inclusion and made digital transactions easier in Southeast Asia, especially in the Philippines, where 94% of users rely on fintech apps for daily transactions (Capstone-Intel Corp., 2024). Integrating locally adopted payment methods is therefore vital for platform success in the Philippine market, as requiring conventional banking relationships would exclude a significant portion of potential users. Cargo's integration of GCash as its primary payment channel directly responds to this reality, ensuring broad accessibility across income levels and geographic areas.

---

### GPS Tracking and Real-Time Accountability

[REVISED] GPS tracking has emerged as a critical feature in peer-to-peer rental platforms, providing real-time location visibility that enhances accountability between transacting parties. When implemented transparently—with users informed of when and how location data is collected—GPS monitoring is shown to increase owner willingness to lend vehicles and renter compliance with rental terms (El-Rabbany, 2002). Cargo employs continuous GPS tracking throughout active rental periods, allowing owners to monitor vehicle whereabouts, enabling the platform to verify mileage against odometer readings, and providing an objective record in the event of a dispute over vehicle usage.

---

### Operational and Policy Challenges

[REVISED] Peer-to-peer rental platforms face operational hurdles including unpredictable vehicle availability, inconsistent insurance frameworks, and the absence of standardized regulations governing liability between private parties (Shaheen et al., 2018). Without clear policies, disputes over vehicle damage, late returns, and payment disagreements can undermine user trust and deter participation. Effective dispute resolution mechanisms, transparent liability disclosures, and structured review processes are therefore essential components of any viable P2P rental platform. Cargo addresses these challenges through its admin-mediated dispute module, defined late fee and overdue policies, and mandatory odometer photo verification at both trip start and end—creating a documented record that supports fair resolution and reduces opportunities for dishonest claims.

---

### Philippine Market Context

The Philippine car rental market—valued at USD 682.27 million in 2025—is growing due to tourism, digital adoption, and mobility programs. Yet, traditional rentals focus on cities, leaving semi-urban areas underserved and creating opportunities for P2P platforms (Mordor Intelligence, 2025).

---

### Local Implementation Studies

Studies in destinations like Siargao Island show problems with manual booking, limited vehicle availability, and poor coordination among rental operators. Digital platforms offering automated bookings and real-time updates can address these gaps (Golo & Encarnacion, 2024).

---

## Synthesis

[REVISED] The synthesis of this literature reveals a consistent set of factors that determine the success or failure of peer-to-peer vehicle rental platforms: trust and identity verification, accessible payment integration, real-time operational accountability, and responsiveness to local market conditions. Cargo is designed to address each of these dimensions directly. The platform's multi-layer verification system—combining government ID validation and facial recognition with admin approval—responds to documented concerns about renter trustworthiness that discourage vehicle owner participation (Balles-Armet et al., 2014; Barbour et al., 2020). Its GCash integration reflects the Philippine market's heavy reliance on mobile financial services (Capstone-Intel Corp., 2024), while its continuous GPS tracking and odometer verification address the operational accountability challenges identified across multiple studies (El-Rabbany, 2002; Shaheen et al., 2018). Furthermore, by incorporating both cars and motorcycles and targeting underserved semi-urban areas identified in local research (Golo & Encarnacion, 2024; Mordor Intelligence, 2025), the Cargo platform is grounded in empirical evidence and positioned as both a practical solution to transportation accessibility challenges and an academically-informed implementation of sharing economy principles within the Philippine context.

---

## References

Balles-Armet, I., Shaheen, S. A., Clonts, K., & Weinzimmer, D. (2014). Peer-to-peer carsharing: Exploring public perception and market characteristics in the San Francisco Bay Area, California. Transportation Research Record, 2416(1), 1-3. https://doi.org/10.3141/2416-04

Barbour, N., Zhang, Y., & Mannering, F. (2020). Individuals' willingness to rent their personal vehicle to others: An exploratory assessment of peer-to-peer carsharing. Transportation Research Interdisciplinary Perspectives, 5, Article 100138. https://doi.org/10.1016/j.trip.2020.100138

El-Rabbany, A. (2002). Introduction to GPS: The global positioning system. Artech House.

Fraiberger, S., & Sundararajan, A. (2016). Peer-to-peer rental markets in the sharing economy. Harvard Business School. https://www.hbs.edu/faculty/Shared%20Documents/conferences/2016-dids/Fraigerber_Sundararajan_March2016.pdf

Golo, M. A. T., & Encarnacion, R. E. (2024). Revolutionizing the rental services in Siargao Island: Basis for developing an online vehicle rental management system. International Journal of Advanced Research in Science Communication and Technology. https://doi.org/10.5281/zenodo.11384832

Mohd, A. (2012). Car rental agency operations and management. Business Management Journal, 8(2), 17. https://www.researchgate.net/publication/365233503

Mordor Intelligence. (2025). Philippines car rental market analysis. https://www.mordorintelligence.com/industry-reports/philippines-car-rental-market

Peer-to-peer carsharing: Market analysis and potential growth. (2011). Transportation Research Record: Journal of the Transportation Research Board, 2217, 1-2. https://doi.org/10.3141/2217-15

Phocuswright. (2022). Looking ahead to a sustainable peer-to-peer car rental segment. In U.S. car rental market report 2021-2025. https://www.phocuswright.com/Travel-Research/Research-Updates/2022/looking-ahead-to-a-sustainable-peer-to-peer-car-rental-segment

Shaheen, S., Cohen, A., & Zohdy, I. (2016). Shared mobility: Current practices and guiding principles. U.S. Department of Transportation, Federal Highway Administration. https://ops.fhwa.dot.gov/publications/fhwahop16022/fhwahop16022.pdf

Shaheen, S., Stocker, A., & Mundler, M. (2018). Online and app-based carpooling in France: Analyzing users and practices. Transportation Research Part D: Transport and Environment, 61, 2-3. https://doi.org/10.1016/j.trd.2017.07.020

Walter, J. (2012). Fleet management strategies in car rental operations. International Journal of Business Operations, 15(3), 12. https://www.researchgate.net/publication/310819591

Wilhelms, M. P., Henkel, S., & Falk, T. (2017). To earn is not enough: A means-end analysis to uncover peer-providers' participation motives in peer-to-peer carsharing. Technological Forecasting and Social Change, 125, 3-4. https://doi.org/10.1016/j.techfore.2017.03.022

Wong, M. (2024, January 7). Philippines: 90% of Filipinos use fintech apps in daily transactions, survey shows. Crowdfund Insider. https://www.crowdfundinsider.com/2024/01/219975-philippines-90-of-filipinos-use-fintech-apps-in-daily-transactions-survey-shows/
