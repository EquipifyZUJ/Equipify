export interface AuthUser {
  id: number
  firstName: string
  lastName: string
  name: string
  emailAddress: string
  phoneNumber: string
  rating: number | null
  status: string
}

export interface Category {
  id: number
  name: string
  nameAr: string | null
  picture: string | null
}

export interface ListingSummary {
  id: number
  title: string
  mainImage: string | null
  rentalUnit: string
  costPerHour: number | null
  costPerDay: number
  costPerWeek: number | null
  costPerMonth: number | null
  minRentalDays: number | null
  maxRentalDays: number | null
  locationAddress: string
  latitude: number
  longitude: number
  categoryId: number
  categoryName: string
  status: string
}

export interface Owner {
  id: number
  name: string
  rating: number | null
  totalRates?: number
}

export interface Listing {
  id: number
  title: string
  description: string
  mainImage: string | null
  images: string[]
  categoryId: number
  categoryName: string
  locationAddress: string
  rentalUnit: string
  costPerHour: number | null
  costPerDay: number
  costPerWeek: number | null
  costPerMonth: number | null
  costPerYear: number | null
  minRentalDays: number | null
  maxRentalDays: number | null
  latitude: number
  longitude: number
  status: string
  createdAt: string
  owner: Owner | null
}

export interface MapMarker {
  id: number
  title: string
  image: string | null
  costPerDay: number
  locationAddress: string
  latitude: number
  longitude: number
}

export interface Paged<T> {
  items: T[]
  page: number
  pageSize: number
  totalCount: number
  totalPages: number
}

export interface RentalRequest {
  id: number
  listingId: number
  listingTitle: string
  listingImage: string | null
  costPerDay: number
  renter: { id: number; name: string; phoneNumber: string }
  fromDate: string
  toDate: string
  fromTime: string
  toTime: string
  totalCost: number
  status: 'Pending' | 'Accepted' | 'Rejected'
  hasRating: boolean
  createdAt: string
}

export interface DashboardStats {
  users: number
  listings: number
  activeListings: number
  pendingListings: number
  categories: number
  requests: number
  pendingRequests: number
}

export interface Review {
  id: number
  renterId: number
  renterName: string
  listingId: number
  listingTitle: string
  rating: number
  createdAt: string
}
