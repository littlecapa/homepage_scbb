<?php
/**
 * Title: SCBB Vereinsabend
 * Slug: scbb/vereinsabend
 * Categories: text
 * Inserter: no
 * Description: Zeiten des Vereinsabends, monatliche Turniere und Spiellokal – auf Deutsch und Englisch mit Umschalter. Erscheint oben auf der Startseite.
 */

// ---- Daten: hier ändern, dann ./deploy.sh ----
$scbb_wochentag = 2; // ISO-Wochentag: 1 = Montag, 2 = Dienstag
$scbb_zeiten    = array(
	array(
		'zeit' => array( 'de' => '17:00–19:00 Uhr', 'en' => '17:00–19:00' ),
		'was'  => array( 'de' => 'Jugendtraining', 'en' => 'Youth training' ),
		'ziel' => '/jugend/', // optional: Link auf eine eigene Seite
	),
	array(
		'zeit' => array( 'de' => 'ab 19:30 Uhr', 'en' => 'from 19:30' ),
		'was'  => array( 'de' => 'Spielabend', 'en' => 'Open play' ),
	),
);
// n-ter Dienstag im Monat => Turnier
$scbb_turniere = array(
	1 => array( 'de' => 'Blitzturnier', 'en' => 'Blitz tournament' ),
	2 => array( 'de' => 'Schnellschachturnier', 'en' => 'Rapid tournament' ),
);
// Feste Texte
$scbb_t = array(
	'de' => array(
		'titel'     => 'Vereinsabend',
		'titel2'    => 'jeden Dienstag',
		'naechster' => 'Nächster Termin:',
		'mit'       => 'mit',
		'heute'     => 'Heute',
		'nter'      => '%s. Dienstag im Monat',
		'ort'       => 'Spiellokal:',
	),
	'en' => array(
		'titel'     => 'Club night',
		'titel2'    => 'every Tuesday',
		'naechster' => 'Next date:',
		'mit'       => 'with',
		'heute'     => 'Today',
		'nter'      => '%s Tuesday of the month',
		'ort'       => 'Venue:',
	),
);
// Spiellokal: zentral in functions.php (scbb_daten)
$scbb_d   = scbb_daten();
$scbb_ort = $scbb_d['ort_name'] . ', ' . $scbb_d['ort_strasse'] . ', ' . $scbb_d['ort_plz_ort'];
$scbb_bus = array( 'de' => $scbb_d['ort_bus'], 'en' => $scbb_d['ort_bus_en'] );
// ----------------------------------------------

// Nächsten Vereinsabend berechnen (heute zählt bis 22 Uhr mit).
$scbb_heute = new DateTimeImmutable( 'now', wp_timezone() );
$scbb_next  = ( (int) $scbb_heute->format( 'N' ) === $scbb_wochentag && (int) $scbb_heute->format( 'G' ) < 22 )
	? $scbb_heute
	: $scbb_heute->modify( 'next ' . array( 1 => 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday' )[ $scbb_wochentag ] );
$scbb_nth       = intdiv( (int) $scbb_next->format( 'j' ) - 1, 7 ) + 1;
$scbb_extra     = $scbb_turniere[ $scbb_nth ] ?? null;
$scbb_ist_heute = $scbb_next->format( 'Y-m-d' ) === $scbb_heute->format( 'Y-m-d' );
$scbb_datum     = array(
	'de' => $scbb_ist_heute ? $scbb_t['de']['heute'] : wp_date( 'l, j. F', $scbb_next->getTimestamp() ),
	'en' => $scbb_ist_heute ? $scbb_t['en']['heute'] : $scbb_next->format( 'l, j F' ), // PHP-Format ist immer englisch
);
$scbb_ordinal = static function ( $n, $sprache ) {
	if ( 'de' === $sprache ) {
		return (string) $n;
	}
	return $n . ( array( 1 => 'st', 2 => 'nd', 3 => 'rd' )[ $n ] ?? 'th' );
};
?>
<!-- wp:html -->
<section class="scbb-abend alignwide" aria-label="Vereinsabend / Club night">
	<label class="scbb-sprache">
		<span class="scbb-sprache__de" aria-hidden="true">DE</span>
		<input type="checkbox" role="switch" class="scbb-sprache__schalter" aria-label="English">
		<span class="scbb-sprache__en" aria-hidden="true">EN</span>
	</label>
	<?php foreach ( array( 'de', 'en' ) as $scbb_l ) : $scbb_tx = $scbb_t[ $scbb_l ]; ?>
	<div class="scbb-abend__inhalt" lang="<?php echo esc_attr( $scbb_l ); ?>">
		<div class="scbb-abend__kopf">
			<h2 class="scbb-abend__titel"><?php echo esc_html( $scbb_tx['titel'] ); ?> <span><?php echo esc_html( $scbb_tx['titel2'] ); ?></span></h2>
			<p class="scbb-abend__naechster">
				<?php echo esc_html( $scbb_tx['naechster'] ); ?> <strong><?php echo esc_html( $scbb_datum[ $scbb_l ] ); ?></strong><?php if ( $scbb_extra ) : ?> – <?php echo esc_html( $scbb_tx['mit'] ); ?> <strong><?php echo esc_html( $scbb_extra[ $scbb_l ] ); ?></strong><?php endif; ?>
			</p>
		</div>
		<div class="scbb-abend__spalten">
			<dl class="scbb-abend__liste">
				<?php foreach ( $scbb_zeiten as $scbb_z ) : ?>
				<div><dt><?php echo esc_html( $scbb_z['zeit'][ $scbb_l ] ); ?></dt><dd><?php if ( ! empty( $scbb_z['ziel'] ) ) : ?><a href="<?php echo esc_url( home_url( $scbb_z['ziel'] ) ); ?>"><?php echo esc_html( $scbb_z['was'][ $scbb_l ] ); ?></a><?php else : ?><?php echo esc_html( $scbb_z['was'][ $scbb_l ] ); ?><?php endif; ?></dd></div>
				<?php endforeach; ?>
			</dl>
			<dl class="scbb-abend__liste">
				<?php foreach ( $scbb_turniere as $scbb_n => $scbb_turnier ) : ?>
				<div><dt><?php echo esc_html( sprintf( $scbb_tx['nter'], $scbb_ordinal( $scbb_n, $scbb_l ) ) ); ?></dt><dd><?php echo esc_html( $scbb_turnier[ $scbb_l ] ); ?></dd></div>
				<?php endforeach; ?>
			</dl>
		</div>
		<p class="scbb-abend__ort"><strong><?php echo esc_html( $scbb_tx['ort'] ); ?></strong> <?php echo esc_html( $scbb_ort ); ?><br><?php echo esc_html( $scbb_bus[ $scbb_l ] ); ?></p>
	</div>
	<?php endforeach; ?>
	<script>
	( function () {
		var s = document.currentScript.parentNode.querySelector( '.scbb-sprache__schalter' );
		try {
			s.checked = localStorage.getItem( 'scbb-sprache' ) === 'en';
			s.addEventListener( 'change', function () {
				localStorage.setItem( 'scbb-sprache', s.checked ? 'en' : 'de' );
			} );
		} catch ( e ) {}
	} )();
	</script>
</section>
<!-- /wp:html -->
