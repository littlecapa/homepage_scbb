<?php
/**
 * Title: SCBB Fußbereich
 * Slug: scbb/footer
 * Categories: footer
 * Block Types: core/template-part/footer
 * Inserter: no
 * Description: Logo, Spiellokal, Kontakt, Vereinslinks und Rechtliches.
 */

$scbb_d    = scbb_daten();
$scbb_logo = get_stylesheet_directory_uri() . '/assets/logo.png';

// Links im Fußbereich: Beschriftung => Pfad.
$scbb_links_verein = array(
	'Über uns'       => '/ueber/',
	'Vorstand'       => '/ueber/vorstand/',
	'Mannschaften'   => '/mannschaften/',
	'Jugend'         => '/jugend/',
	'Termine'        => '/termine/',
);
$scbb_links_recht = array(
	'Impressum'   => '/impressum/',
	'Datenschutz' => '/datenschutz/',
	'Kontakt'     => '/kontakt/',
);
?>
<!-- wp:html -->
<div class="scbb-footer">
	<div class="scbb-footer__inner">
		<div class="scbb-footer__verein">
			<a href="<?php echo esc_url( home_url( '/' ) ); ?>" class="scbb-footer__logo" aria-label="Zur Startseite">
				<img src="<?php echo esc_url( $scbb_logo ); ?>" alt="" width="72" height="72" loading="lazy">
			</a>
			<p class="scbb-footer__name"><?php echo esc_html( $scbb_d['name'] ); ?></p>
			<p class="scbb-footer__slogan"><?php echo esc_html( get_bloginfo( 'description' ) ); ?></p>
		</div>

		<div class="scbb-footer__spalte">
			<h2 class="scbb-footer__titel">Spiellokal</h2>
			<p>
				<?php echo esc_html( $scbb_d['ort_name'] ); ?><br>
				<?php echo esc_html( $scbb_d['ort_strasse'] ); ?><br>
				<?php echo esc_html( $scbb_d['ort_plz_ort'] ); ?>
			</p>
			<p class="scbb-footer__klein"><?php echo esc_html( $scbb_d['ort_bus'] ); ?></p>
		</div>

		<div class="scbb-footer__spalte">
			<h2 class="scbb-footer__titel">Verein</h2>
			<ul>
				<?php foreach ( $scbb_links_verein as $scbb_label => $scbb_pfad ) : ?>
				<li><a href="<?php echo esc_url( home_url( $scbb_pfad ) ); ?>"><?php echo esc_html( $scbb_label ); ?></a></li>
				<?php endforeach; ?>
			</ul>
		</div>

		<div class="scbb-footer__spalte">
			<h2 class="scbb-footer__titel">Kontakt</h2>
			<p><a href="mailto:<?php echo esc_attr( $scbb_d['email'] ); ?>"><?php echo esc_html( $scbb_d['email'] ); ?></a></p>
			<ul>
				<?php foreach ( $scbb_links_recht as $scbb_label => $scbb_pfad ) : ?>
				<li><a href="<?php echo esc_url( home_url( $scbb_pfad ) ); ?>"><?php echo esc_html( $scbb_label ); ?></a></li>
				<?php endforeach; ?>
			</ul>
		</div>
	</div>
	<div class="scbb-footer__unten">
		<p>© <?php echo esc_html( wp_date( 'Y' ) ); ?> <?php echo esc_html( $scbb_d['name'] ); ?></p>
	</div>
</div>
<!-- /wp:html -->
