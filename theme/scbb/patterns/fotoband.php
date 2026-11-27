<?php
/**
 * Title: SCBB Fotoband
 * Slug: scbb/fotoband
 * Categories: text
 * Inserter: no
 * Description: Beitragsbilder der neuesten News (Desktop: nebeneinander, Handy: Karussell zum Wischen). Klick führt zum Beitrag.
 */

// ---- Anzahl der Fotos; News ohne Beitragsbild werden übersprungen ----
$scbb_fotos_anzahl = 4;
// ---------------------------------------------------------------------

$scbb_fotos = get_posts(
	array(
		'numberposts'      => $scbb_fotos_anzahl,
		'post_status'      => 'publish',
		'meta_key'         => '_thumbnail_id', // nur Beiträge mit Beitragsbild
		'suppress_filters' => false,
	)
);
if ( ! $scbb_fotos ) {
	return;
}
?>
<!-- wp:html -->
<section class="scbb-fotoband alignwide" aria-label="Fotos der neuesten News">
	<div class="scbb-fotoband__spur">
		<?php foreach ( $scbb_fotos as $scbb_post ) : ?>
		<a class="scbb-fotoband__foto" href="<?php echo esc_url( get_permalink( $scbb_post ) ); ?>">
			<?php
			echo wp_get_attachment_image(
				get_post_thumbnail_id( $scbb_post ),
				'medium_large',
				false,
				array(
					'alt'     => '', // Titel steht darunter im Link
					'loading' => 'lazy',
					'sizes'   => '(max-width: 700px) 100vw, 600px' // 600px: scharf auf Retina-Bildschirmen,
				)
			);
			?>
			<span class="scbb-fotoband__titel"><?php echo esc_html( get_the_title( $scbb_post ) ); ?></span>
		</a>
		<?php endforeach; ?>
	</div>
	<?php if ( count( $scbb_fotos ) > 1 ) : ?>
	<div class="scbb-fotoband__punkte" aria-hidden="true">
		<?php foreach ( $scbb_fotos as $scbb_i => $scbb_post ) : ?>
		<button type="button" tabindex="-1" data-nr="<?php echo (int) $scbb_i; ?>"<?php echo 0 === $scbb_i ? ' class="ist-aktiv"' : ''; ?>></button>
		<?php endforeach; ?>
	</div>
	<script>
	/* Handy-Karussell: Punkte zeigen das aktuelle Foto, Tippen springt dorthin */
	( function () {
		var band = document.currentScript.closest( '.scbb-fotoband' );
		var spur = band.querySelector( '.scbb-fotoband__spur' );
		var punkte = band.querySelectorAll( '.scbb-fotoband__punkte button' );
		spur.addEventListener( 'scroll', function () {
			var nr = Math.round( spur.scrollLeft / spur.clientWidth );
			punkte.forEach( function ( p, i ) { p.classList.toggle( 'ist-aktiv', i === nr ); } );
		}, { passive: true } );
		punkte.forEach( function ( p, i ) {
			p.addEventListener( 'click', function () {
				spur.scrollTo( { left: i * spur.clientWidth, behavior: 'smooth' } );
			} );
		} );
	} )();
	</script>
	<?php endif; ?>
</section>
<!-- /wp:html -->
