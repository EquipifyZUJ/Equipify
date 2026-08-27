import { useState } from 'react'
import { useI18n } from '../i18n'

const faqData = {
  ar: [
    { q: 'ما هو Equipify؟', a: 'Equipify هو منصة لتأجير المعدات والأدوات بين الأفراد. يمكنك تأجير أي شيء تملكه أو استئجار ما تحتاجه بسهولة وأمان.' },
    { q: 'كيف أبدأ بتأجير معداتي؟', a: 'قم بإنشاء حساب، ثم اضغط على "أريد أن أُؤجّر" وأضف تفاصيل المعدة مع الصور والأسعار. بعد موافقة الإدارة، سيظهر إعلانك على المنصة.' },
    { q: 'هل الخدمة مجانية؟', a: 'التسجيل والتصفح مجاني تماماً. يتم تحصيل رسوم بسيطة فقط عند إتمام عملية تأجير ناجحة.' },
    { q: 'كيف أستأجر معدة؟', a: 'ابحث عن المعدة التي تحتاجها، حدد التواريخ والأوقات، ثم أرسل طلب حجز. سيقوم المالك بمراجعة طلبك والموافقة عليه أو رفضه.' },
    { q: 'ما هو نظام OTP؟', a: 'لحماية حسابك، نرسل رمز تحقق (OTP) مكون من 4 أرقام إلى هاتفك عند التسجيل أو استرجاع كلمة المرور. في البيئة التجريبية الرمز دائماً 0000.' },
    { q: 'كيف أسترجع كلمة المرور؟', a: 'اذهب لصفحة تسجيل الدخول واضغط "نسيت كلمة المرور". أدخل رقم هاتفك وسنرسل لك رمز تحقق لإعادة تعيين كلمة المرور.' },
    { q: 'ما هي مدة الإيجار المسموحة؟', a: 'يحدد المالك الحد الأدنى والأقصى لمدة الإيجار. بعض المعدات متاحة بالساعة، وبعضها بالشهر أو أكثر.' },
    { q: 'كيف أضمن سلامة معداتي؟', a: 'ننصح بالتواصل مع المستأجر مسبقاً والاتفاق على شروط الاستخدام. يمكنك تقييم المستأجرين بعد كل عملية.' },
  ],
  en: [
    { q: 'What is Equipify?', a: 'Equipify is a peer-to-peer equipment rental platform. You can rent out anything you own or rent what you need easily and safely.' },
    { q: 'How do I start renting out?', a: 'Create an account, click "I want to rent out", add your equipment details with photos and pricing. After admin approval, your listing goes live.' },
    { q: 'Is the service free?', a: 'Registration and browsing are completely free. A small fee is charged only on successful rental transactions.' },
    { q: 'How do I rent equipment?', a: 'Search for what you need, select dates and times, then send a booking request. The owner will review and approve or decline.' },
    { q: 'What is the OTP system?', a: 'For security, we send a 4-digit verification code (OTP) to your phone during registration or password recovery. In the demo environment, the code is always 0000.' },
    { q: 'How do I recover my password?', a: 'Go to the login page and click "Forgot password". Enter your phone number and we\'ll send a verification code to reset it.' },
    { q: 'What rental durations are allowed?', a: 'Owners set minimum and maximum rental durations. Some equipment is available hourly, others monthly or longer.' },
    { q: 'How do I ensure my equipment is safe?', a: 'We recommend communicating with renters beforehand and agreeing on usage terms. You can rate renters after each transaction.' },
  ]
}

export default function FAQ() {
  const { t, lang } = useI18n()
  const items = lang === 'ar' ? faqData.ar : faqData.en
  const [open, setOpen] = useState<number | null>(null)

  return (
    <div className="faq-page animate-fadeInUp">
      <div className="center" style={{ marginBottom: 40 }}>
        <h1 className="section-title">{t('faq.title')}</h1>
        <p className="muted">{t('faq.subtitle')}</p>
      </div>

      <div className="faq-list">
        {items.map((item, i) => (
          <div key={i} className={`faq-item glass ${open === i ? 'faq-open' : ''}`}
            onClick={() => setOpen(open === i ? null : i)}>
            <div className="faq-q">
              <span>{item.q}</span>
              <span className="faq-icon">{open === i ? '−' : '+'}</span>
            </div>
            <div className="faq-a">
              <p>{item.a}</p>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
