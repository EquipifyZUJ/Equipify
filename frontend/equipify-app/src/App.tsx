import { lazy, Suspense } from 'react'
import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom'
import { Layout } from './components/layout/Layout'
import { Spinner } from './components/ui'
import { AppBanner } from './components/AppBanner'

const Home = lazy(() => import('./pages/Home'))
const Browse = lazy(() => import('./pages/Browse'))
const ListingDetails = lazy(() => import('./pages/ListingDetails'))
const ListingForm = lazy(() => import('./pages/ListingForm'))
const MyListings = lazy(() => import('./pages/MyListings'))
const AuthLogin = lazy(() => import('./pages/Auth').then(m => ({ default: m.Login })))
const AuthRegister = lazy(() => import('./pages/Auth').then(m => ({ default: m.Register })))
const Profile = lazy(() => import('./pages/Profile'))
const MyRequests = lazy(() => import('./pages/Requests').then(m => ({ default: m.MyRequests })))
const IncomingRequests = lazy(() => import('./pages/Requests').then(m => ({ default: m.IncomingRequests })))
const FAQ = lazy(() => import('./pages/FAQ'))
const Terms = lazy(() => import('./pages/Terms'))
const Download = lazy(() => import('./pages/Download'))

const AdminLayout = lazy(() => import('./pages/admin/AdminLayout'))
const AdminDashboard = lazy(() => import('./pages/admin/AdminPages').then(m => ({ default: m.AdminDashboard })))
const AdminUsers = lazy(() => import('./pages/admin/AdminPages').then(m => ({ default: m.AdminUsers })))
const AdminListings = lazy(() => import('./pages/admin/AdminPages').then(m => ({ default: m.AdminListings })))
const AdminCategories = lazy(() => import('./pages/admin/AdminPages').then(m => ({ default: m.AdminCategories })))
const AdminRequests = lazy(() => import('./pages/admin/AdminPages').then(m => ({ default: m.AdminRequests })))

export default function App() {
  return (
    <BrowserRouter>
      <div className="liquid-bg" aria-hidden />
      <AppBanner />
      <Suspense fallback={<Spinner />}>
        <Routes>
          <Route element={<Layout />}>
            <Route index element={<Home />} />
            <Route path="browse" element={<Browse />} />
            <Route path="map" element={<Browse mapOnly />} />
            <Route path="listings/:id" element={<ListingDetails />} />
            <Route path="login" element={<AuthLogin />} />
            <Route path="register" element={<AuthRegister />} />
            <Route path="profile" element={<Profile />} />
            <Route path="my-listings" element={<MyListings />} />
            <Route path="my-listings/new" element={<ListingForm />} />
            <Route path="my-listings/:id/edit" element={<ListingForm />} />
            <Route path="requests" element={<MyRequests />} />
            <Route path="incoming" element={<IncomingRequests />} />
            <Route path="faq" element={<FAQ />} />
            <Route path="terms" element={<Terms />} />
            <Route path="download" element={<Download />} />

            {/* Admin area (guarded by role inside AdminLayout) */}
            <Route path="admin" element={<AdminLayout />}>
              <Route index element={<AdminDashboard />} />
              <Route path="listings" element={<AdminListings />} />
              <Route path="users" element={<AdminUsers />} />
              <Route path="categories" element={<AdminCategories />} />
              <Route path="requests" element={<AdminRequests />} />
            </Route>

            <Route path="*" element={<Navigate to="/" replace />} />
          </Route>
        </Routes>
      </Suspense>
    </BrowserRouter>
  )
}
