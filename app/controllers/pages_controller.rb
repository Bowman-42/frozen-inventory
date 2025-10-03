class PagesController < ApplicationController
  def pricing
    @selected_language = params[:lang] || session[:language] || 'en'
    session[:language] = @selected_language

    @pricing_data = {
      'en' => {
        title: 'English',
        currency_symbol: '$',
        header: { plan: 'Plan', price: 'Price' },
        plans: [
          { name: 'Free (Household)', price: '$0' },
          { name: 'Pro (Household)', price: '$5/mo or $15 one-time' },
          { name: 'Business Starter', price: '$20/mo' },
          { name: 'Business Pro', price: '$50/mo' },
          { name: 'Self-Hosted License', price: '$300 one-time or $25/mo' }
        ]
      },
      'sv' => {
        title: 'Svenska',
        currency_symbol: 'kr',
        header: { plan: 'Plan', price: 'Pris' },
        plans: [
          { name: 'Gratis (Hushåll)', price: '0 kr' },
          { name: 'Pro (Hushåll)', price: '50 kr/mån eller 150 kr engångs' },
          { name: 'Företag Start', price: '200 kr/mån' },
          { name: 'Företag Pro', price: '500 kr/mån' },
          { name: 'Egen server-licens', price: '3 000 kr engångs eller 250 kr/mån' }
        ]
      },
      'de' => {
        title: 'Deutsch',
        currency_symbol: '€',
        header: { plan: 'Plan', price: 'Preis' },
        plans: [
          { name: 'Kostenlos (Haushalt)', price: '0 €' },
          { name: 'Pro (Haushalt)', price: '5 €/Monat oder 15 € einmalig' },
          { name: 'Business Starter', price: '20 €/Monat' },
          { name: 'Business Pro', price: '50 €/Monat' },
          { name: 'Selbstgehostete Lizenz', price: '300 € einmalig oder 25 €/Monat' }
        ]
      }
    }

    @languages = {
      'en' => 'English',
      'sv' => 'Svenska',
      'de' => 'Deutsch'
    }
  end
end