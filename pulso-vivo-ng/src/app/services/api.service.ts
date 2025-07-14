import { Injectable, PLATFORM_ID, inject } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable, throwError, from, of, timer } from 'rxjs';
import { catchError, switchMap, retryWhen, delay, take, mergeMap, filter, first, timeout } from 'rxjs/operators';
import { isPlatformBrowser } from '@angular/common';
import { AuthService } from '../auth/auth.service';
import { environment } from '../../environments/environment';

export interface ApiResponse<T> {
  data: T;
  success: boolean;
  message?: string;
  errors?: string[];
}

export interface ProductoApi {
  id: number;
  name: string;
  description: string;
  quantity: number;
  category: string;
  active: boolean;
}

export interface InventoryUpdateRequest {
  quantityChanged: number;
}

@Injectable({
  providedIn: 'root'
})
export class ApiService {
  private readonly baseUrl = environment.api.baseUrl + '/inventory';
  private platformId = inject(PLATFORM_ID);
  private isBrowser = isPlatformBrowser(this.platformId);
  
  constructor(
    private http: HttpClient,
    private authService: AuthService
  ) {}

  /**
   * Crea los headers HTTP con JWT token para autenticación
   */
  private async createHeaders(): Promise<HttpHeaders> {
    let headers = new HttpHeaders({
      'Content-Type': 'application/json'
    });

    // Add JWT token if user is authenticated
    if (this.isBrowser) {
      try {
        if (environment.app.enableLogging) {
          console.log('[API Service] Attempting to get BFF token...');
        }
        
        const token = await this.authService.getBffToken();
        if (token) {
          headers = headers.set('Authorization', `Bearer ${token}`);
          if (environment.app.enableLogging) {
            console.log('[API Service] Token added to headers successfully');
          }
        } else {
          if (environment.app.enableLogging) {
            console.warn('[API Service] No token available');
          }
        }
      } catch (error) {
        console.warn('[API Service] Could not get authentication token:', error);
      }
    }

    return headers;
  }

  /**
   * Verifica si el usuario está autenticado antes de hacer llamadas API
   */
  private ensureAuthenticated(): Observable<boolean> {
    if (!this.isBrowser) {
      return of(false);
    }

    // Check if user is already authenticated
    if (this.authService.isAuthenticated()) {
      if (environment.app.enableLogging) {
        console.log('[API Service] User is authenticated');
      }
      return of(true);
    }

    if (environment.app.enableLogging) {
      console.log('[API Service] User not authenticated, waiting...');
    }

    // Wait for authentication to complete (up to 15 seconds)
    return this.authService.isAuthenticated$.pipe(
      filter(isAuth => isAuth === true),
      first(),
      timeout(15000),
      catchError(() => {
        if (environment.app.enableLogging) {
          console.warn('[API Service] Authentication timeout, proceeding without auth');
        }
        return of(false);
      })
    );
  }

  /**
   * Maneja errores de las llamadas HTTP
   */
  private handleError(error: any): Observable<never> {
    if (environment.app.enableLogging) {
      console.error('[API Service] Error en llamada API:', error);
      console.error('[API Service] Error details:', {
        status: error.status,
        statusText: error.statusText,
        url: error.url,
        message: error.message
      });
    }
    
    if (error.status === 401) {
      if (environment.app.enableLogging) {
        console.log('[API Service] 401 Unauthorized - Token issue detected');
        console.log('[API Service] Current auth status:', this.authService.isAuthenticated());
      }
      
      // Try to get fresh token if user is authenticated
      if (this.authService.isAuthenticated()) {
        if (environment.app.enableLogging) {
          console.log('[API Service] User is authenticated but token may be expired');
        }
      } else {
        if (environment.app.enableLogging) {
          console.log('[API Service] User not authenticated, login required');
        }
        // Trigger login only if not already in progress
        this.authService.login();
      }
    }
    
    return throwError(() => error);
  }

  // === MÉTODOS PARA PRODUCTOS ===

  /**
   * Obtiene todos los productos
   */
  getProductos(): Observable<ProductoApi[]> {
    // Return mock data during SSR to prevent build failures
    if (!this.isBrowser) {
      return of(this.getMockProducts());
    }
    
    return this.ensureAuthenticated().pipe(
      switchMap(isAuth => {
        if (!isAuth) {
          if (environment.app.enableLogging) {
            console.warn('[API Service] Usuario no autenticado, usando datos mock para productos');
          }
          return of(this.getMockProducts());
        }
        
        if (environment.app.enableLogging) {
          console.log('[API Service] Making authenticated request to get products');
        }
        
        return from(this.createHeaders()).pipe(
          switchMap(headers => {
            if (environment.app.enableLogging) {
              console.log('[API Service] Request URL:', `${this.baseUrl}/products`);
              console.log('[API Service] Request headers:', headers.keys());
            }
            
            return this.http.get<ProductoApi[]>(`${this.baseUrl}/products`, { headers })
              .pipe(
                catchError(error => {
                  if (environment.app.enableLogging) {
                    console.error('[API Service] getProductos failed:', error);
                  }
                  return this.handleError(error);
                })
              );
          })
        );
      })
    );
  }

  /**
   * Obtiene un producto por ID
   */
  getProducto(id: number): Observable<ProductoApi> {
    // Return mock data during SSR to prevent build failures
    if (!this.isBrowser) {
      const mockProducts = this.getMockProducts();
      const product = mockProducts.find(p => p.id === id);
      return of(product || mockProducts[0]);
    }
    
    return from(this.createHeaders()).pipe(
      switchMap(headers => 
        this.http.get<ProductoApi>(`${this.baseUrl}/products/${id}`, { headers })
          .pipe(catchError(this.handleError.bind(this)))
      )
    );
  }

  /**
   * Crea un nuevo producto
   */
  crearProducto(producto: Partial<ProductoApi>): Observable<ProductoApi> {
    return from(this.createHeaders()).pipe(
      switchMap(headers => 
        this.http.post<ProductoApi>(`${this.baseUrl}/products`, producto, { headers })
          .pipe(catchError(this.handleError.bind(this)))
      )
    );
  }

  /**
   * Actualiza un producto existente
   */
  actualizarProducto(id: number, producto: Partial<ProductoApi>): Observable<ProductoApi> {
    return from(this.createHeaders()).pipe(
      switchMap(headers => 
        this.http.put<ProductoApi>(`${this.baseUrl}/products/${id}`, producto, { headers })
          .pipe(catchError(this.handleError.bind(this)))
      )
    );
  }

  /**
   * Actualiza el stock de un producto
   */
  actualizarStock(id: number, quantityChanged: number): Observable<void> {
    const request: InventoryUpdateRequest = { quantityChanged };
    return from(this.createHeaders()).pipe(
      switchMap(headers => 
        this.http.patch<void>(`${this.baseUrl}/products/${id}/stock`, request, { headers })
          .pipe(catchError(this.handleError.bind(this)))
      )
    );
  }

  /**
   * Obtiene productos con stock bajo
   */
  getProductosStockBajo(): Observable<ProductoApi[]> {
    // Return mock data during SSR to prevent build failures
    if (!this.isBrowser) {
      const mockProducts = this.getMockProducts();
      return of(mockProducts.filter(p => p.quantity < 10));
    }
    
    return this.ensureAuthenticated().pipe(
      switchMap(isAuth => {
        if (!isAuth) {
          if (environment.app.enableLogging) {
            console.warn('Usuario no autenticado, usando datos mock para stock bajo');
          }
          const mockProducts = this.getMockProducts();
          return of(mockProducts.filter(p => p.quantity < 10));
        }
        
        return from(this.createHeaders()).pipe(
          switchMap(headers => 
            this.http.get<ProductoApi[]>(`${this.baseUrl}/low-stock`, { headers })
              .pipe(catchError(this.handleError.bind(this)))
          )
        );
      })
    );
  }

  // === MÉTODOS NO DISPONIBLES EN INVENTORY SERVICE ===
  // TODO: Implementar estos endpoints en el inventory service o remover del frontend

  /**
   * Busca productos por término - TODO: Implementar en inventory service
   */
  buscarProductos(termino: string): Observable<ProductoApi[]> {
    // Fallback: filtrar localmente por ahora
    return this.getProductos().pipe(
      switchMap(productos => 
        [productos.filter(p => 
          p.name.toLowerCase().includes(termino.toLowerCase()) ||
          p.description.toLowerCase().includes(termino.toLowerCase())
        )]
      )
    );
  }

  /**
   * Filtra productos por categoría - TODO: Implementar en inventory service
   */
  filtrarProductosPorCategoria(categoria: string): Observable<ProductoApi[]> {
    // Fallback: filtrar localmente por ahora
    return this.getProductos().pipe(
      switchMap(productos => 
        [productos.filter(p => p.category === categoria)]
      )
    );
  }

  /**
   * Obtiene todas las categorías disponibles - TODO: Implementar en inventory service
   */
  getCategorias(): Observable<string[]> {
    // Return mock categories during SSR
    if (!this.isBrowser) {
      return of(['Equipos de Diagnóstico', 'Suministros Desechables', 'Mobiliario Médico']);
    }
    
    return this.ensureAuthenticated().pipe(
      switchMap(isAuth => {
        if (!isAuth) {
          if (environment.app.enableLogging) {
            console.warn('[API Service] Usuario no autenticado, usando categorías mock');
          }
          return of(['Equipos de Diagnóstico', 'Suministros Desechables', 'Mobiliario Médico']);
        }
        
        if (environment.app.enableLogging) {
          console.log('[API Service] Getting categories from products');
        }
        
        // Fallback: extraer categorías de productos existentes
        return this.getProductos().pipe(
          switchMap(productos => {
            const categorias = [...new Set(productos.map(p => p.category))];
            if (environment.app.enableLogging) {
              console.log('[API Service] Categories extracted:', categorias);
            }
            return [categorias];
          })
        );
      })
    );
  }

  // === MÉTODOS UTILITARIOS ===

  /**
   * Provides mock data for SSR builds
   */
  private getMockProducts(): ProductoApi[] {
    return [
      {
        id: 1,
        name: 'Tensiómetro Digital',
        description: 'Tensiómetro digital automático para uso doméstico',
        quantity: 15,
        category: 'Equipos de Diagnóstico',
        active: true
      },
      {
        id: 2,
        name: 'Estetoscopio Profesional',
        description: 'Estetoscopio de alta calidad para diagnóstico médico',
        quantity: 8,
        category: 'Equipos de Diagnóstico',
        active: true
      },
      {
        id: 3,
        name: 'Termómetro Digital',
        description: 'Termómetro digital de lectura rápida',
        quantity: 0,
        category: 'Equipos de Diagnóstico',
        active: true
      },
      {
        id: 4,
        name: 'Guantes Desechables',
        description: 'Caja de guantes desechables de nitrilo',
        quantity: 50,
        category: 'Suministros Desechables',
        active: true
      },
      {
        id: 5,
        name: 'Mascarillas Quirúrgicas',
        description: 'Mascarillas quirúrgicas desechables',
        quantity: 100,
        category: 'Suministros Desechables',
        active: true
      },
      {
        id: 6,
        name: 'Jeringuillas Desechables',
        description: 'Jeringuillas desechables estériles',
        quantity: 25,
        category: 'Suministros Desechables',
        active: true
      },
      {
        id: 7,
        name: 'Camilla Médica',
        description: 'Camilla médica ajustable para consulta',
        quantity: 3,
        category: 'Mobiliario Médico',
        active: true
      },
      {
        id: 8,
        name: 'Silla de Ruedas',
        description: 'Silla de ruedas plegable para pacientes',
        quantity: 5,
        category: 'Mobiliario Médico',
        active: true
      }
    ];
  }

  // TODO: Implementar health check y version endpoints en inventory service si son necesarios
}