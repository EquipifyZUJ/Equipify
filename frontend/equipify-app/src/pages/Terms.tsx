import { useI18n } from '../i18n'

export default function Terms() {
  const { t, lang } = useI18n()

  return (
    <div className="terms-page animate-fadeInUp">
      <div className="center" style={{ marginBottom: 40 }}>
        <h1 className="section-title">{t('terms.title')}</h1>
      </div>

      <div className="terms-content glass-strong">
        {lang === 'ar' ? (
          <>
            <section>
              <h2>1. مقدمة</h2>
              <p>مرحباً بك في Equipify. باستخدامك للمنصة، فإنك توافق على الالتزام بهذه الشروط والأحكام. يرجى قراءتها بعناية قبل استخدام خدماتنا.</p>
            </section>
            <section>
              <h2>2. التسجيل والحساب</h2>
              <p>يجب عليك تقديم معلومات دقيقة وصحيحة عند التسجيل. أنت مسؤول عن الحفاظ على سرية كلمة المرور وجميع الأنشطة التي تتم من خلال حسابك.</p>
            </section>
            <section>
              <h2>3. الإعلانات والتأجير</h2>
              <p>يجب أن تكون جميع المعدات المعروضة للتأجير مملوكة لك قانونياً. يحق للإدارة مراجعة وحذف أي إعلان لا يتوافق مع سياسات المنصة. تخضع جميع الإعلانات لموافقة الإدارة قبل النشر.</p>
            </section>
            <section>
              <h2>4. المدفوعات والأسعار</h2>
              <p>يتم تحديد أسعار التأجير من قبل المالك. يمكن تحديد الأسعار بالساعة أو اليوم أو الأسبوع أو الشهر أو السنة. يلتزم المستأجر بدفع المبلغ المتفق عليه في الوقت المحدد.</p>
            </section>
            <section>
              <h2>5. المسؤولية</h2>
              <p>المستأجر مسؤول عن أي ضرر يلحق بالمعدات أثناء فترة الإيجار. يجب إعادة المعدات بنفس الحالة التي تم استلامها بها. Equipify ليست مسؤولة عن أي نزاعات بين المالك والمستأجر.</p>
            </section>
            <section>
              <h2>6. الخصوصية</h2>
              <p>نحترم خصوصيتك ونلتزم بحماية بياناتك الشخصية. لن نشارك معلوماتك مع أطراف ثالثة إلا بموافقتك أو وفقاً لمتطلبات القانون.</p>
            </section>
            <section>
              <h2>7. إنهاء الحساب</h2>
              <p>يحق لنا تعليق أو إنهاء حسابك في حالة مخالفة هذه الشروط. يمكنك أيضاً حذف حسابك في أي وقت من خلال التواصل مع الدعم.</p>
            </section>
            <section>
              <h2>8. التعديلات</h2>
              <p>نحتفظ بالحق في تعديل هذه الشروط في أي وقت. سيتم إخطارك بأي تغييرات جوهرية عبر البريد الإلكتروني أو من خلال إشعار على المنصة.</p>
            </section>
          </>
        ) : (
          <>
            <section>
              <h2>1. Introduction</h2>
              <p>Welcome to Equipify. By using our platform, you agree to be bound by these Terms and Conditions. Please read them carefully before using our services.</p>
            </section>
            <section>
              <h2>2. Registration and Account</h2>
              <p>You must provide accurate and truthful information when registering. You are responsible for maintaining the confidentiality of your password and all activities that occur through your account.</p>
            </section>
            <section>
              <h2>3. Listings and Rentals</h2>
              <p>All equipment listed for rent must be legally owned by you. The administration reserves the right to review and delete any listing that does not comply with platform policies. All listings are subject to admin approval before publication.</p>
            </section>
            <section>
              <h2>4. Payments and Pricing</h2>
              <p>Rental prices are set by the owner. Prices can be set per hour, day, week, month, or year. The renter is committed to paying the agreed amount on time.</p>
            </section>
            <section>
              <h2>5. Liability</h2>
              <p>The renter is responsible for any damage to the equipment during the rental period. Equipment must be returned in the same condition it was received. Equipify is not liable for any disputes between the owner and the renter.</p>
            </section>
            <section>
              <h2>6. Privacy</h2>
              <p>We respect your privacy and are committed to protecting your personal data. We will not share your information with third parties without your consent or as required by law.</p>
            </section>
            <section>
              <h2>7. Account Termination</h2>
              <p>We reserve the right to suspend or terminate your account if you violate these terms. You may also delete your account at any time by contacting support.</p>
            </section>
            <section>
              <h2>8. Amendments</h2>
              <p>We reserve the right to modify these terms at any time. You will be notified of any material changes via email or through a platform notification.</p>
            </section>
          </>
        )}
      </div>
    </div>
  )
}
