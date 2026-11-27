<?php
/**
 * Title: SCBB Bereiche
 * Slug: scbb/bereiche
 * Categories: text
 * Inserter: no
 * Description: Vier Bereiche (2x2) auf der Startseite: News, Turniere, Mannschaften, Jugend – jeweils mit Pfeil zur Detailseite.
 */

// ---- Reihenfolge: hier einfach umstellen (je zwei pro Reihe), dann ./deploy.sh ----
$scbb_reihenfolge = array( 'news', 'turniere', 'mannschaften', 'jugend' );

// ---- Bereiche: Titel, Detailseite, Linktext, kurzer Text ----
$scbb_bereiche = array(
	'news'         => array(
		'titel' => 'News',
		'pfad'  => '/news/',
		'link'  => 'Alle News',
		'text'  => '', // News zeigen die neuesten Beiträge (siehe unten)
	),
	'turniere'     => array(
		'titel' => 'Turniere',
		'pfad'  => '/turniere/',
		'link'  => 'Zu den Turnieren',
		'text'  => 'Jeden Monat zwei Vereinsturniere am Dienstagabend: am 1. Dienstag Blitz, am 2. Dienstag Schnellschach.',
	),
	'mannschaften' => array(
		'titel' => 'Mannschaften',
		'pfad'  => '/mannschaften/',
		'link'  => 'Zu den Mannschaften',
		'text'  => 'Unsere Mannschaften im Spielbetrieb des Schachverbands Mittelrhein und der Schachjugend Mittelrhein.',
	),
	'jugend'       => array(
		'titel' => 'Jugend',
		'pfad'  => '/jugend/',
		'link'  => 'Zur Schachjugend',
		'text'  => 'Jugendtraining jeden Dienstag, 17–19 Uhr. Einfach vorbeikommen – die ersten Trainings sind kostenlos.',
	),
);
$scbb_news_anzahl = 3;
// ------------------------------------------------------------------------------------

$scbb_news = get_posts(
	array(
		'numberposts'      => $scbb_news_anzahl,
		'post_status'      => 'publish',
		'suppress_filters' => false,
	)
);
?>
<!-- wp:html -->
<section class="scbb-bereiche alignwide" aria-label="Bereiche">
	<?php foreach ( $scbb_reihenfolge as $scbb_key ) : ?>
		<?php
		if ( empty( $scbb_bereiche[ $scbb_key ] ) ) {
			continue;
		}
		$scbb_b = $scbb_bereiche[ $scbb_key ];
		?>
	<article class="scbb-bereich scbb-bereich--<?php echo esc_attr( $scbb_key ); ?>">
		<h2 class="scbb-bereich__titel"><a href="<?php echo esc_url( home_url( $scbb_b['pfad'] ) ); ?>"><?php echo esc_html( $scbb_b['titel'] ); ?></a></h2>
		<?php if ( 'news' === $scbb_key ) : ?>
			<?php if ( $scbb_news ) : ?>
		<ul class="scbb-bereich__liste">
				<?php foreach ( $scbb_news as $scbb_post ) : ?>
			<li><a href="<?php echo esc_url( get_permalink( $scbb_post ) ); ?>"><?php echo esc_html( get_the_title( $scbb_post ) ); ?></a> <time datetime="<?php echo esc_attr( get_the_date( 'c', $scbb_post ) ); ?>"><?php echo esc_html( get_the_date( 'j.n.Y', $scbb_post ) ); ?></time></li>
				<?php endforeach; ?>
		</ul>
			<?php else : ?>
		<p>Hier erscheinen Neuigkeiten und Berichte aus dem Verein.</p>
			<?php endif; ?>
		<?php else : ?>
		<p><?php echo esc_html( $scbb_b['text'] ); ?></p>
		<?php endif; ?>
		<p class="scbb-bereich__mehr"><a href="<?php echo esc_url( home_url( $scbb_b['pfad'] ) ); ?>"><?php echo esc_html( $scbb_b['link'] ); ?> <span aria-hidden="true">→</span></a></p>
	</article>
	<?php endforeach; ?>
</section>
<!-- /wp:html -->
