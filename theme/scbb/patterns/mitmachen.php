<?php
/**
 * Title: SCBB Unterstützen & Folgen
 * Slug: scbb/mitmachen
 * Categories: call-to-action
 * Inserter: no
 * Description: Zwei Kacheln auf der Startseite: Spendenprojekt für die Schachjugend und Instagram-Kanal.
 */

$scbb_d = scbb_daten();
?>
<!-- wp:html -->
<section class="scbb-kacheln alignwide" aria-label="Unterstützen und folgen">
	<a class="scbb-kachel scbb-kachel--spenden" href="<?php echo esc_url( $scbb_d['spenden'] ); ?>" target="_blank" rel="noopener">
		<span class="scbb-kachel__icon"><?php echo scbb_icon_herz( 30 ); // phpcs:ignore WordPress.Security.EscapeOutput ?></span>
		<span class="scbb-kachel__text">
			<strong>Unterstützt unsere Schachjugend</strong>
			<span>Mit einer Spende für unser Projekt bei „Hier mit Herz“ unterstützt ihr die Jugendarbeit unseres Vereins.</span>
		</span>
		<span class="scbb-kachel__pfeil" aria-hidden="true">→</span>
	</a>
	<a class="scbb-kachel scbb-kachel--insta" href="<?php echo esc_url( $scbb_d['instagram'] ); ?>" target="_blank" rel="noopener">
		<span class="scbb-kachel__icon"><?php echo scbb_icon_instagram( 30 ); // phpcs:ignore WordPress.Security.EscapeOutput ?></span>
		<span class="scbb-kachel__text">
			<strong>Folgt uns auf Instagram</strong>
			<span><?php echo esc_html( $scbb_d['insta_name'] ); ?> – unser Verein auf Instagram.</span>
		</span>
		<span class="scbb-kachel__pfeil" aria-hidden="true">→</span>
	</a>
</section>
<!-- /wp:html -->
