<?php
/**
 * Title: SCBB Kopfbereich
 * Slug: scbb/header
 * Categories: header
 * Block Types: core/template-part/header
 * Inserter: no
 * Description: Logo, Vereinsname, Slogan und Menüleiste.
 */

$scbb_logo = get_stylesheet_directory_uri() . '/assets/logo.png';
$scbb_d    = scbb_daten();

// Menüpunkte: Beschriftung => Pfad. Seiten, die es noch nicht gibt, führen vorerst ins Leere.
$scbb_menu = array(
	'Startseite'   => '/',
	'Über uns'     => '/ueber/',
	'Mannschaften' => '/mannschaften/',
	'Jugend'       => '/jugend/',
	'Turniere'     => '/turniere/',
	'Termine'      => '/termine/',
	'Kontakt'      => '/kontakt/',
);
?>
<!-- wp:group {"tagName":"header","className":"scbb-header","layout":{"type":"default"}} -->
<header class="wp-block-group scbb-header">
	<!-- wp:group {"className":"scbb-header__top","layout":{"type":"flex","flexWrap":"nowrap","verticalAlignment":"center"}} -->
	<div class="wp-block-group scbb-header__top">
		<!-- wp:html -->
		<a class="scbb-header__logo" href="<?php echo esc_url( home_url( '/' ) ); ?>" aria-label="Zur Startseite"><img src="<?php echo esc_url( $scbb_logo ); ?>" alt="Logo Schachclub Bonn Beuel" width="150" height="150"></a>
		<!-- /wp:html -->

		<!-- wp:group {"className":"scbb-header__titles","layout":{"type":"flex","orientation":"vertical"}} -->
		<div class="wp-block-group scbb-header__titles">
			<!-- wp:site-title {"level":0,"className":"scbb-header__title"} /-->
			<!-- wp:site-tagline {"className":"scbb-header__tagline"} /-->
		</div>
		<!-- /wp:group -->
	</div>
	<!-- /wp:group -->

	<!-- wp:group {"className":"scbb-header__nav","layout":{"type":"flex","flexWrap":"nowrap","justifyContent":"space-between","verticalAlignment":"center"}} -->
	<div class="wp-block-group scbb-header__nav">
		<!-- wp:navigation {"className":"scbb-nav","overlayMenu":"mobile","layout":{"type":"flex","justifyContent":"left","flexWrap":"wrap"}} -->
		<?php foreach ( $scbb_menu as $scbb_label => $scbb_path ) : ?>
		<!-- wp:navigation-link <?php echo wp_json_encode( array( 'label' => $scbb_label, 'url' => home_url( $scbb_path ), 'kind' => 'custom', 'isTopLevelLink' => true ), JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES ); ?> /-->
		<?php endforeach; ?>
		<!-- /wp:navigation -->

		<!-- wp:html -->
		<div class="scbb-header__aktionen">
			<a class="scbb-header__insta" href="<?php echo esc_url( $scbb_d['instagram'] ); ?>" target="_blank" rel="noopener" aria-label="Instagram: <?php echo esc_attr( $scbb_d['insta_name'] ); ?>" title="Instagram"><?php echo scbb_icon_instagram( 22 ); // phpcs:ignore WordPress.Security.EscapeOutput ?></a>
			<a class="scbb-button scbb-button--spenden" href="<?php echo esc_url( $scbb_d['spenden'] ); ?>" target="_blank" rel="noopener"><?php echo scbb_icon_herz( 16 ); // phpcs:ignore WordPress.Security.EscapeOutput ?><span>Jugend unterstützen</span></a>
		</div>
		<!-- /wp:html -->
	</div>
	<!-- /wp:group -->
</header>
<!-- /wp:group -->
