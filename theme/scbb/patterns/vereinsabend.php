<?php
/**
 * Title: SCBB Vereinsabend
 * Slug: scbb/vereinsabend
 * Categories: text
 * Inserter: no
 * Description: Zeiten des Vereinsabends, monatliche Turniere und Spiellokal. Erscheint oben auf der Startseite.
 */

// ---- Daten: hier ändern, dann ./deploy.sh ----
$scbb_wochentag = 2; // ISO-Wochentag: 1 = Montag, 2 = Dienstag
$scbb_zeiten    = array(
	'17:00–19:00 Uhr' => 'Jugendtraining',
	'ab 19:30 Uhr'    => 'Spielabend',
);
// n-ter Dienstag im Monat => Turnier
$scbb_turniere = array(
	1 => 'Blitzturnier',
	2 => 'Schnellschachturnier',
);
// Spiellokal: zentral in functions.php (scbb_daten)
$scbb_d   = scbb_daten();
$scbb_ort = $scbb_d['ort_name'] . ', ' . $scbb_d['ort_strasse'] . ', ' . $scbb_d['ort_plz_ort'];
$scbb_bus = $scbb_d['ort_bus'];
// ----------------------------------------------

// Nächsten Vereinsabend berechnen (heute zählt bis 22 Uhr mit).
$scbb_heute = new DateTimeImmutable( 'now', wp_timezone() );
$scbb_next  = ( (int) $scbb_heute->format( 'N' ) === $scbb_wochentag && (int) $scbb_heute->format( 'G' ) < 22 )
	? $scbb_heute
	: $scbb_heute->modify( 'next ' . array( 1 => 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday' )[ $scbb_wochentag ] );
$scbb_nth     = intdiv( (int) $scbb_next->format( 'j' ) - 1, 7 ) + 1;
$scbb_extra   = $scbb_turniere[ $scbb_nth ] ?? '';
$scbb_ist_heute = $scbb_next->format( 'Y-m-d' ) === $scbb_heute->format( 'Y-m-d' );
$scbb_datum   = $scbb_ist_heute ? 'Heute' : wp_date( 'l, j. F', $scbb_next->getTimestamp() );
?>
<!-- wp:html -->
<section class="scbb-abend alignwide" aria-labelledby="scbb-abend-titel">
	<div class="scbb-abend__kopf">
		<h2 id="scbb-abend-titel" class="scbb-abend__titel">Vereinsabend <span>jeden Dienstag</span></h2>
		<p class="scbb-abend__naechster">
			Nächster Termin: <strong><?php echo esc_html( $scbb_datum ); ?></strong><?php if ( $scbb_extra ) : ?> – mit <strong><?php echo esc_html( $scbb_extra ); ?></strong><?php endif; ?>
		</p>
	</div>
	<div class="scbb-abend__spalten">
		<dl class="scbb-abend__liste">
			<?php foreach ( $scbb_zeiten as $scbb_zeit => $scbb_was ) : ?>
			<div><dt><?php echo esc_html( $scbb_zeit ); ?></dt><dd><?php echo esc_html( $scbb_was ); ?></dd></div>
			<?php endforeach; ?>
		</dl>
		<dl class="scbb-abend__liste">
			<?php foreach ( $scbb_turniere as $scbb_n => $scbb_turnier ) : ?>
			<div><dt><?php echo esc_html( $scbb_n ); ?>. Dienstag im Monat</dt><dd><?php echo esc_html( $scbb_turnier ); ?></dd></div>
			<?php endforeach; ?>
		</dl>
	</div>
	<p class="scbb-abend__ort"><strong>Spiellokal:</strong> <?php echo esc_html( $scbb_ort ); ?><br><?php echo esc_html( $scbb_bus ); ?></p>
</section>
<!-- /wp:html -->
