import { createContext, useContext, useEffect, useState, type ReactNode } from 'react'
import { ar } from './ar'
import { en } from './en'

export type Lang = 'ar' | 'en'

const dicts = { ar, en }
export type Key = keyof typeof ar

interface I18n {
  lang: Lang
  dir: 'rtl' | 'ltr'
  setLang: (l: Lang) => void
  toggle: () => void
  t: (key: Key, vars?: Record<string, string | number>) => string
}

const I18nContext = createContext<I18n>(null!)

function initial(): Lang {
  return (localStorage.getItem('equipify.lang') as Lang) ?? 'ar'
}

export function I18nProvider({ children }: { children: ReactNode }) {
  const [lang, setLangState] = useState<Lang>(initial)

  useEffect(() => {
    document.documentElement.lang = lang
    document.documentElement.dir = lang === 'ar' ? 'rtl' : 'ltr'
    localStorage.setItem('equipify.lang', lang)
  }, [lang])

  const t: I18n['t'] = (key, vars) => {
    let text: string = dicts[lang][key] ?? key
    if (vars) for (const [k, v] of Object.entries(vars)) text = text.replace(`{${k}}`, String(v))
    return text
  }

  return (
    <I18nContext.Provider
      value={{
        lang,
        dir: lang === 'ar' ? 'rtl' : 'ltr',
        setLang: setLangState,
        toggle: () => setLangState(l => (l === 'ar' ? 'en' : 'ar')),
        t,
      }}
    >
      {children}
    </I18nContext.Provider>
  )
}

export function useI18n() {
  return useContext(I18nContext)
}
