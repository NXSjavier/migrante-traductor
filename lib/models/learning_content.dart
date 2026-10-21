/// Learning curriculum: 8 levels that take a Spanish speaker from zero to a
/// fluent everyday conversation in English.
///
/// Levels follow the CEFR scale loosely: A0 survival, A1 daily life, A2 work,
/// B1 health and paperwork, B2 discussion and idioms.
class LearningSentence {
  final String spanish;
  final String english;
  final String? tip;

  const LearningSentence(this.spanish, this.english, {this.tip});
}

class LearningLesson {
  final String id;
  final String title;
  final String goal;
  final List<LearningSentence> sentences;

  const LearningLesson({
    required this.id,
    required this.title,
    required this.goal,
    required this.sentences,
  });
}

class LearningLevel {
  final int number;
  final String title;
  final String cefr;
  final String description;
  final List<LearningLesson> lessons;

  const LearningLevel({
    required this.number,
    required this.title,
    required this.cefr,
    required this.description,
    required this.lessons,
  });
}

const List<LearningLevel> learningLevels = [
  LearningLevel(
    number: 1,
    title: 'Primeros pasos',
    cefr: 'A0',
    description: 'Saludos, presentarte y pedir lo básico.',
    lessons: [
      LearningLesson(
        id: 'l1-greetings',
        title: 'Saludos',
        goal: 'Saludar y despedirte en cualquier momento del día.',
        sentences: [
          LearningSentence('Hola.', 'Hello.'),
          LearningSentence('¿Cómo estás?', 'How are you?'),
          LearningSentence('Bien, gracias.', 'Fine, thank you.'),
          LearningSentence('Buenos días.', 'Good morning.'),
          LearningSentence('Buenas noches.', 'Good night.'),
        ],
      ),
      LearningLesson(
        id: 'l1-introduce',
        title: 'Presentarte',
        goal: 'Decir tu nombre, de dónde sos y qué idioma hablás.',
        sentences: [
          LearningSentence('Me llamo Ana.', 'My name is Ana.'),
          LearningSentence('Soy de Perú.', 'I am from Peru.'),
          LearningSentence('Tengo veinticinco años.', 'I am twenty-five years old.'),
          LearningSentence('Vivo en esta ciudad.', 'I live in this city.'),
          LearningSentence('Hablo un poco de inglés.', 'I speak a little English.'),
        ],
      ),
      LearningLesson(
        id: 'l1-politeness',
        title: 'Cortesía',
        goal: 'Las cinco palabras que más vas a usar.',
        sentences: [
          LearningSentence('Por favor.', 'Please.'),
          LearningSentence('Gracias.', 'Thank you.'),
          LearningSentence('Perdón.', 'Excuse me.'),
          LearningSentence('Lo siento.', 'I am sorry.'),
          LearningSentence('De nada.', 'You are welcome.'),
        ],
      ),
      LearningLesson(
        id: 'l1-numbers',
        title: 'Números y hora',
        goal: 'Preguntar precios, la hora y pedir cantidades.',
        sentences: [
          LearningSentence('¿Cuánto cuesta?', 'How much does it cost?'),
          LearningSentence('Son cinco dólares.', 'It is five dollars.'),
          LearningSentence('¿Qué hora es?', 'What time is it?'),
          LearningSentence('Son las tres.', 'It is three o\'clock.'),
          LearningSentence('Necesito dos boletos.', 'I need two tickets.'),
        ],
      ),
    ],
  ),
  LearningLevel(
    number: 2,
    title: 'Vida diaria',
    cefr: 'A1',
    description: 'Tu rutina, compras, comida y cómo moverte.',
    lessons: [
      LearningLesson(
        id: 'l2-routine',
        title: 'Mi rutina',
        goal: 'Contar qué hacés durante el día.',
        sentences: [
          LearningSentence('Me levanto a las seis.', 'I get up at six.'),
          LearningSentence('Desayuno café y pan.', 'I have coffee and bread for breakfast.'),
          LearningSentence('Voy al trabajo en autobús.', 'I go to work by bus.'),
          LearningSentence('Almuerzo a la una.', 'I have lunch at one.'),
          LearningSentence('Me acuesto tarde.', 'I go to bed late.'),
        ],
      ),
      LearningLesson(
        id: 'l2-shopping',
        title: 'Compras',
        goal: 'Pedir talles, probarte ropa y devolver algo.',
        sentences: [
          LearningSentence('¿Tienen esto en talla grande?', 'Do you have this in a large size?'),
          LearningSentence('¿Dónde está el probador?', 'Where is the fitting room?'),
          LearningSentence('Busco algo más barato.', 'I am looking for something cheaper.'),
          LearningSentence('¿Puedo pagar con tarjeta?', 'Can I pay by card?'),
          LearningSentence('Quiero devolver esto.', 'I want to return this.'),
        ],
      ),
      LearningLesson(
        id: 'l2-food',
        title: 'En el restaurante',
        goal: 'Pedir mesa, plato y la cuenta.',
        sentences: [
          LearningSentence('Una mesa para dos, por favor.', 'A table for two, please.'),
          LearningSentence('¿Qué me recomienda?', 'What do you recommend?'),
          LearningSentence('Quiero el pollo con arroz.', 'I would like the chicken with rice.'),
          LearningSentence('Sin picante, por favor.', 'Not spicy, please.'),
          LearningSentence('La cuenta, por favor.', 'The bill, please.'),
        ],
      ),
      LearningLesson(
        id: 'l2-directions',
        title: 'Direcciones',
        goal: 'Preguntar cómo llegar y entender la respuesta.',
        sentences: [
          LearningSentence('¿Dónde está el supermercado?', 'Where is the supermarket?'),
          LearningSentence('Gire a la derecha.', 'Turn right.'),
          LearningSentence('Siga recto dos calles.', 'Go straight for two blocks.'),
          LearningSentence('Está cerca de la estación.', 'It is near the station.'),
          LearningSentence('¿Está lejos de aquí?', 'Is it far from here?'),
        ],
      ),
    ],
  ),
  LearningLevel(
    number: 3,
    title: 'Vida social',
    cefr: 'A1+',
    description: 'Familia, gustos, planes e invitaciones.',
    lessons: [
      LearningLesson(
        id: 'l3-family',
        title: 'Familia y amigos',
        goal: 'Hablar de tu gente.',
        sentences: [
          LearningSentence('Esta es mi familia.', 'This is my family.'),
          LearningSentence('Tengo dos hermanos.', 'I have two brothers.'),
          LearningSentence('Mi hijo va a la escuela.', 'My son goes to school.'),
          LearningSentence('Mis padres viven en mi país.', 'My parents live in my country.'),
          LearningSentence('Somos una familia unida.', 'We are a close family.'),
        ],
      ),
      LearningLesson(
        id: 'l3-likes',
        title: 'Gustos',
        goal: 'Decir qué te gusta y preguntar por el otro.',
        sentences: [
          LearningSentence('Me gusta la música.', 'I like music.'),
          LearningSentence('No me gusta el frío.', 'I do not like the cold.'),
          LearningSentence('Prefiero el té al café.', 'I prefer tea to coffee.'),
          LearningSentence('Me encanta cocinar.', 'I love cooking.'),
          LearningSentence('¿A ti qué te gusta?', 'What do you like?'),
        ],
      ),
      LearningLesson(
        id: 'l3-plans',
        title: 'Planes',
        goal: 'Proponer y acordar una salida.',
        sentences: [
          LearningSentence('¿Qué vas a hacer el fin de semana?', 'What are you going to do this weekend?'),
          LearningSentence('Voy a visitar a unos amigos.', 'I am going to visit some friends.'),
          LearningSentence('Podemos salir el sábado.', 'We can go out on Saturday.'),
          LearningSentence('¿Quieres venir con nosotros?', 'Do you want to come with us?'),
          LearningSentence('Nos vemos a las ocho.', 'See you at eight.'),
        ],
      ),
      LearningLesson(
        id: 'l3-invitations',
        title: 'Invitaciones',
        goal: 'Invitar a alguien y agradecer una invitación.',
        sentences: [
          LearningSentence('¿Te gustaría cenar en mi casa?', 'Would you like to have dinner at my place?'),
          LearningSentence('Trae algo de beber.', 'Bring something to drink.'),
          LearningSentence('Gracias por la invitación.', 'Thank you for the invitation.'),
          LearningSentence('Lo pasé muy bien.', 'I had a great time.'),
          LearningSentence('La próxima vez invito yo.', 'Next time it is on me.'),
        ],
      ),
    ],
  ),
  LearningLevel(
    number: 4,
    title: 'Trabajo',
    cefr: 'A2',
    description: 'Buscar empleo, entrevistas y el día a día laboral.',
    lessons: [
      LearningLesson(
        id: 'l4-job-search',
        title: 'Buscar trabajo',
        goal: 'Ofrecerte para un puesto y dejar tu currículum.',
        sentences: [
          LearningSentence('Estoy buscando trabajo.', 'I am looking for a job.'),
          LearningSentence('Vi su anuncio en internet.', 'I saw your ad online.'),
          LearningSentence('Tengo experiencia en limpieza.', 'I have experience in cleaning.'),
          LearningSentence('Puedo trabajar los fines de semana.', 'I can work on weekends.'),
          LearningSentence('¿Puedo dejar mi currículum?', 'Can I leave my resume?'),
        ],
      ),
      LearningLesson(
        id: 'l4-interview',
        title: 'La entrevista',
        goal: 'Presentarte en una entrevista de trabajo.',
        sentences: [
          LearningSentence('Gracias por recibirme.', 'Thank you for seeing me.'),
          LearningSentence('Cuénteme sobre usted.', 'Tell me about yourself.'),
          LearningSentence('Trabajé tres años en un almacén.', 'I worked in a warehouse for three years.'),
          LearningSentence('Soy puntual y responsable.', 'I am punctual and reliable.'),
          LearningSentence('¿Cuándo puedo empezar?', 'When can I start?'),
        ],
      ),
      LearningLesson(
        id: 'l4-at-work',
        title: 'En el trabajo',
        goal: 'Pedir ayuda, entender tareas y tomar un descanso.',
        sentences: [
          LearningSentence('Mi turno empieza a las siete.', 'My shift starts at seven.'),
          LearningSentence('Necesito ayuda con esta caja.', 'I need help with this box.'),
          LearningSentence('¿Dónde guardo las herramientas?', 'Where do I put the tools?'),
          LearningSentence('Ya terminé mi tarea.', 'I have finished my task.'),
          LearningSentence('¿Puedo tomar un descanso?', 'Can I take a break?'),
        ],
      ),
      LearningLesson(
        id: 'l4-problems',
        title: 'Problemas en el trabajo',
        goal: 'Avisar de un error y pedir hablar con un supervisor.',
        sentences: [
          LearningSentence('No entiendo esta instrucción.', 'I do not understand this instruction.'),
          LearningSentence('¿Puede repetirlo más despacio?', 'Can you repeat it more slowly?'),
          LearningSentence('Hubo un error con mi pago.', 'There was a mistake with my pay.'),
          LearningSentence('Necesito hablar con el supervisor.', 'I need to speak with the supervisor.'),
          LearningSentence('No me siento seguro haciendo eso.', 'I do not feel safe doing that.'),
        ],
      ),
    ],
  ),
  LearningLevel(
    number: 5,
    title: 'Casa y dinero',
    cefr: 'A2+',
    description: 'Alquiler, banco, servicios y reclamos.',
    lessons: [
      LearningLesson(
        id: 'l5-rent',
        title: 'Alquilar',
        goal: 'Preguntar por un alquiler y firmar con seguridad.',
        sentences: [
          LearningSentence('Busco un apartamento para rentar.', 'I am looking for an apartment to rent.'),
          LearningSentence('¿Cuánto es la renta mensual?', 'How much is the monthly rent?'),
          LearningSentence('¿Está incluido el agua?', 'Is water included?'),
          LearningSentence('Necesito un contrato por escrito.', 'I need a written contract.'),
          LearningSentence('¿Cuándo puedo mudarme?', 'When can I move in?'),
        ],
      ),
      LearningLesson(
        id: 'l5-bank',
        title: 'El banco',
        goal: 'Abrir una cuenta y resolver cobros erróneos.',
        sentences: [
          LearningSentence('Quiero abrir una cuenta.', 'I want to open an account.'),
          LearningSentence('Necesito mi tarjeta nueva.', 'I need my new card.'),
          LearningSentence('¿Cuál es el horario del banco?', 'What are the bank hours?'),
          LearningSentence('Quiero transferir dinero.', 'I want to transfer money.'),
          LearningSentence('Me cobraron dos veces.', 'I was charged twice.'),
        ],
      ),
      LearningLesson(
        id: 'l5-services',
        title: 'Servicios de la casa',
        goal: 'Pedir reparaciones y contratar servicios.',
        sentences: [
          LearningSentence('Se cortó la luz.', 'The power went out.'),
          LearningSentence('No tengo agua caliente.', 'I do not have hot water.'),
          LearningSentence('Quiero contratar internet.', 'I want to get internet service.'),
          LearningSentence('¿Cuánto cuesta el servicio?', 'How much does the service cost?'),
          LearningSentence('El técnico viene mañana.', 'The technician is coming tomorrow.'),
        ],
      ),
      LearningLesson(
        id: 'l5-complaints',
        title: 'Reclamos',
        goal: 'Reclamar, pedir devolución y escalar el problema.',
        sentences: [
          LearningSentence('Quiero hacer un reclamo.', 'I want to file a complaint.'),
          LearningSentence('Esto no funciona.', 'This does not work.'),
          LearningSentence('Necesito una devolución.', 'I need a refund.'),
          LearningSentence('¿Puedo hablar con un gerente?', 'Can I speak with a manager?'),
          LearningSentence('Voy a llamar a la oficina del consumidor.', 'I am going to call the consumer office.'),
        ],
      ),
    ],
  ),
  LearningLevel(
    number: 6,
    title: 'Salud y trámites',
    cefr: 'B1',
    description: 'Médico, farmacia, emergencias y documentos.',
    lessons: [
      LearningLesson(
        id: 'l6-doctor',
        title: 'El médico',
        goal: 'Pedir turno y explicar qué te duele.',
        sentences: [
          LearningSentence('Necesito un turno con el médico.', 'I need an appointment with the doctor.'),
          LearningSentence('Me duele la cabeza.', 'I have a headache.'),
          LearningSentence('Tengo fiebre desde ayer.', 'I have had a fever since yesterday.'),
          LearningSentence('Soy alérgico a la penicilina.', 'I am allergic to penicillin.'),
          LearningSentence('¿Cada cuánto tomo la medicina?', 'How often should I take the medicine?'),
        ],
      ),
      LearningLesson(
        id: 'l6-pharmacy',
        title: 'La farmacia',
        goal: 'Comprar un remedio entendiendo la receta.',
        sentences: [
          LearningSentence('Necesito algo para el dolor.', 'I need something for the pain.'),
          LearningSentence('¿Tiene receta?', 'Do you have a prescription?'),
          LearningSentence('¿Hay algo más barato?', 'Is there anything cheaper?'),
          LearningSentence('¿Puede explicarme las instrucciones?', 'Can you explain the instructions to me?'),
          LearningSentence('¿Tiene efectos secundarios?', 'Does it have side effects?'),
        ],
      ),
      LearningLesson(
        id: 'l6-emergency',
        title: 'Emergencias',
        goal: 'Pedir ayuda urgente con claridad.',
        sentences: [
          LearningSentence('Llame a una ambulancia.', 'Call an ambulance.'),
          LearningSentence('Mi hijo se cayó.', 'My son fell down.'),
          LearningSentence('No puedo respirar bien.', 'I cannot breathe well.'),
          LearningSentence('¿Dónde está la sala de emergencias?', 'Where is the emergency room?'),
          LearningSentence('Necesito ayuda ahora.', 'I need help now.'),
        ],
      ),
      LearningLesson(
        id: 'l6-documents',
        title: 'Documentos y citas',
        goal: 'Moverte en oficinas de inmigración.',
        sentences: [
          LearningSentence('Quiero renovar mi pasaporte.', 'I want to renew my passport.'),
          LearningSentence('¿Qué documentos necesito?', 'What documents do I need?'),
          LearningSentence('¿Dónde queda la oficina de inmigración?', 'Where is the immigration office?'),
          LearningSentence('Mi cita es el lunes.', 'My appointment is on Monday.'),
          LearningSentence('Perdí mi tarjeta de residencia.', 'I lost my residence card.'),
        ],
      ),
    ],
  ),
  LearningLevel(
    number: 7,
    title: 'Conversación',
    cefr: 'B1+',
    description: 'Opiniones, argumentos, historias y teléfono.',
    lessons: [
      LearningLesson(
        id: 'l7-opinions',
        title: 'Dar tu opinión',
        goal: 'Expresar acuerdo y desacuerdo con cortesía.',
        sentences: [
          LearningSentence('En mi opinión, es una buena idea.', 'In my opinion, it is a good idea.'),
          LearningSentence('Creo que tienes razón.', 'I think you are right.'),
          LearningSentence('No estoy de acuerdo contigo.', 'I do not agree with you.'),
          LearningSentence('Depende de la situación.', 'It depends on the situation.'),
          LearningSentence('Estoy de acuerdo en parte.', 'I partly agree.'),
        ],
      ),
      LearningLesson(
        id: 'l7-arguments',
        title: 'Argumentar',
        goal: 'Sostener una idea sin pelear.',
        sentences: [
          LearningSentence('Entiendo tu punto, pero...', 'I see your point, but...'),
          LearningSentence('Por un lado..., por otro lado...', 'On one hand..., on the other hand...'),
          LearningSentence('Tienes un buen argumento.', 'You have a good point.'),
          LearningSentence('No es tan simple como parece.', 'It is not as simple as it seems.'),
          LearningSentence('Podemos llegar a un acuerdo.', 'We can reach an agreement.'),
        ],
      ),
      LearningLesson(
        id: 'l7-stories',
        title: 'Contar historias',
        goal: 'Narrar algo que te pasó con orden.',
        sentences: [
          LearningSentence('Cuando llegué, no había nadie.', 'When I arrived, there was nobody there.'),
          LearningSentence('De repente, empezó a llover.', 'Suddenly, it started to rain.'),
          LearningSentence('Al principio fue difícil.', 'At first, it was difficult.'),
          LearningSentence('Con el tiempo me acostumbré.', 'Over time, I got used to it.'),
          LearningSentence('Nunca voy a olvidar ese día.', 'I will never forget that day.'),
        ],
      ),
      LearningLesson(
        id: 'l7-phone',
        title: 'Teléfono y mensajes',
        goal: 'Resolver una llamada rápida.',
        sentences: [
          LearningSentence('Hola, ¿quién habla?', 'Hello, who is calling?'),
          LearningSentence('Te llamo más tarde.', 'I will call you later.'),
          LearningSentence('No te escucho bien.', 'I cannot hear you well.'),
          LearningSentence('¿Me mandas un mensaje?', 'Can you send me a message?'),
          LearningSentence('Ya te aviso cuando llegue.', 'I will let you know when I arrive.'),
        ],
      ),
    ],
  ),
  LearningLevel(
    number: 8,
    title: 'Fluidez',
    cefr: 'B2',
    description: 'Phrasal verbs, expresiones y negociación real.',
    lessons: [
      LearningLesson(
        id: 'l8-phrasal',
        title: 'Phrasal verbs esenciales',
        goal: 'Los verbos compuestos que aparecen todo el tiempo.',
        sentences: [
          LearningSentence('Tengo que llenar este formulario.', 'I need to fill out this form.',
              tip: 'fill out = completar un formulario'),
          LearningSentence('Voy a encargarme de eso.', 'I will take care of it.',
              tip: 'take care of = ocuparse de algo'),
          LearningSentence('Descubrí la verdad.', 'I found out the truth.',
              tip: 'find out = descubrir información'),
          LearningSentence('No puedo seguir el ritmo.', 'I cannot keep up.',
              tip: 'keep up = mantener el ritmo'),
          LearningSentence('Déjame pensarlo.', 'Let me think it over.',
              tip: 'think over = pensarlo con calma'),
        ],
      ),
      LearningLesson(
        id: 'l8-idioms',
        title: 'Expresiones idiomáticas',
        goal: 'Sonar natural, no traducido palabra por palabra.',
        sentences: [
          LearningSentence('Está lloviendo a cántaros.', 'It is raining cats and dogs.',
              tip: 'Literalmente "llueven gatos y perros".'),
          LearningSentence('Costó un ojo de la cara.', 'It cost an arm and a leg.',
              tip: 'Se usa para algo muy caro.'),
          LearningSentence('Estoy en la misma situación.', 'I am in the same boat.',
              tip: 'Literalmente "en el mismo barco".'),
          LearningSentence('Me tomó por sorpresa.', 'It caught me off guard.',
              tip: 'caught off guard = agarrar desprevenido'),
          LearningSentence('Al final todo salió bien.', 'Everything turned out fine in the end.',
              tip: 'turn out = resultar'),
        ],
      ),
      LearningLesson(
        id: 'l8-debate',
        title: 'Debatir',
        goal: 'Manejar un desacuerdo sin perder el hilo.',
        sentences: [
          LearningSentence('Eso no viene al caso.', 'That is beside the point.'),
          LearningSentence('Déjame terminar.', 'Let me finish.'),
          LearningSentence('¿Qué quieres decir con eso?', 'What do you mean by that?'),
          LearningSentence('Hay que ver ambos lados.', 'We have to look at both sides.'),
          LearningSentence('Lleguemos a un punto medio.', 'Let us meet halfway.',
              tip: 'meet halfway = ceder un poco cada uno'),
        ],
      ),
      LearningLesson(
        id: 'l8-negotiate',
        title: 'Negociar y resolver',
        goal: 'Cerrar un trato o defender tu posición.',
        sentences: [
          LearningSentence('¿Podemos dividir la diferencia?', 'Can we split the difference?'),
          LearningSentence('Necesito una garantía por escrito.', 'I need a written guarantee.'),
          LearningSentence('Estoy dispuesto a esperar.', 'I am willing to wait.'),
          LearningSentence('Eso no me conviene.', 'That does not work for me.'),
          LearningSentence('Quedamos así, entonces.', 'Let us leave it at that, then.'),
        ],
      ),
    ],
  ),
];

int get totalLearningLessons =>
    learningLevels.fold(0, (sum, level) => sum + level.lessons.length);

int get totalLearningSentences => learningLevels.fold(
      0,
      (sum, level) =>
          sum +
          level.lessons.fold(0, (s, lesson) => s + lesson.sentences.length),
    );

/// Every sentence of the curriculum, used by the mixed review and the phrase
/// browser. The list is a copy, so callers can shuffle it freely.
List<LearningSentence> allLearningSentences() => [
      for (final level in learningLevels)
        for (final lesson in level.lessons) ...lesson.sentences,
    ];

/// Builds a mixed practice lesson with random sentences from every level.
LearningLesson buildReviewLesson({int count = 10}) {
  final sentences = allLearningSentences()..shuffle();
  return LearningLesson(
    id: 'review-all',
    title: 'Repaso general',
    goal: 'Frases al azar de todos los niveles.',
    sentences: sentences.take(count).toList(),
  );
}

/// Wraps [buildReviewLesson] so it can be opened with the regular lesson flow.
LearningLevel buildReviewLevel({int count = 10}) => LearningLevel(
      number: 0,
      title: 'Repaso general',
      cefr: 'A0-B2',
      description: 'Mezcla de frases de todos los niveles.',
      lessons: [buildReviewLesson(count: count)],
    );
