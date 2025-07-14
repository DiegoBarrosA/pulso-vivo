import { Component, OnInit, PLATFORM_ID, inject, AfterViewInit } from '@angular/core';
import { CommonModule, isPlatformBrowser } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { AuthService } from '../../auth/auth.service';
import { ApiService, ProductoApi } from '../../services/api.service';
import { Observable } from 'rxjs';

export interface ProductoStock {
  id: number;
  name: string;
  description: string;
  quantity: number;
  category: string;
  active: boolean;
  // Legacy fields for display compatibility - TODO: Remove after UI update
  nombre?: string;
  descripcion?: string;
  cantidadStock?: number;
  precio?: number;
  stockMinimo?: number;
  proveedor?: string;
  fechaActualizacion?: Date;
  activo?: boolean;
}

export interface MovimientoStock {
  id: number;
  productoId: number;
  productoNombre: string;
  tipo: 'entrada' | 'salida' | 'ajuste';
  cantidad: number;
  motivo: string;
  fecha: Date;
  usuario: string;
}

@Component({
  selector: 'app-administracion',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  templateUrl: './administracion.component.html',
  styleUrls: ['./administracion.component.less']
})
export class AdministracionComponent implements OnInit, AfterViewInit {
  // Estado del componente
  vistaActual: 'inventario' | 'movimientos' | 'reportes' = 'inventario';
  
  // Datos del inventario
  productos: ProductoStock[] = [];
  productosFiltrados: ProductoStock[] = [];
  movimientos: MovimientoStock[] = [];
  
  // Filtros y búsqueda
  terminoBusqueda: string = '';
  categoriaFiltro: string = '';
  estadoFiltro: string = '';
  categorias: string[] = [];
  
  // Modal y formularios
  mostrarModal: boolean = false;
  modoModal: 'crear' | 'editar' | 'movimiento' = 'crear';
  productoSeleccionado: ProductoStock | null = null;
  
  // Formulario de producto
  formularioProducto: Partial<ProductoStock> = {
    name: '',
    description: '',
    quantity: 0,
    category: '',
    active: true,
    // Legacy fields for form compatibility
    nombre: '',
    descripcion: '',
    cantidadStock: 0,
    activo: true
  };
  
  // Formulario de movimiento
  formularioMovimiento = {
    tipo: 'entrada' as 'entrada' | 'salida' | 'ajuste',
    cantidad: 0,
    motivo: ''
  };
  
  // Estadísticas
  estadisticas = {
    totalProductos: 0,
    productosActivos: 0,
    productosStockBajo: 0,
    valorInventario: 0
  };

  // Platform detection for SSR
  private platformId = inject(PLATFORM_ID);
  private isBrowser = isPlatformBrowser(this.platformId);

  constructor(
    private authService: AuthService,
    private apiService: ApiService
  ) {}

  ngOnInit(): void {
    // Load sample data immediately for SSR
    if (!this.isBrowser) {
      this.cargarDatosMuestra();
    }
  }

  ngAfterViewInit(): void {
    // Load real data only in browser after view initialization
    if (this.isBrowser) {
      this.cargarProductos();
      this.cargarCategorias();
      this.cargarMovimientos();
    }
  }

  // === CARGA DE DATOS DESDE API ===
  private cargarProductos(): void {
    this.apiService.getProductos().subscribe({
      next: (productos) => {
        // Convert API products to display format with legacy field mapping
        this.productos = productos.map(p => ({
          ...p,
          // Legacy field mappings for existing UI
          nombre: p.name,
          descripcion: p.description,
          cantidadStock: p.quantity,
          activo: p.active,
          categoria: p.category,
          // Default values for fields not in API
          precio: 0,
          stockMinimo: 5,
          proveedor: 'N/A',
          fechaActualizacion: new Date()
        }));
        this.productosFiltrados = [...this.productos];
        this.calcularEstadisticas();
      },
      error: (error) => {
        console.error('Error loading products:', error);
        this.cargarDatosMuestra(); // Fallback to sample data
      }
    });
  }

  private cargarCategorias(): void {
    // Skip API calls during SSR
    if (!this.isBrowser) {
      return;
    }

    this.apiService.getCategorias().subscribe({
      next: (categorias) => {
        this.categorias = categorias;
      },
      error: (error) => {
        console.error('Error loading categories:', error);
        this.categorias = ['Equipos de Diagnóstico', 'Suministros Desechables', 'Mobiliario Médico'];
      }
    });
  }

  private cargarMovimientos(): void {
    // Skip API calls during SSR
    if (!this.isBrowser) {
      return;
    }

    // TODO: Implement movements API endpoint
    // For now, generate mock movement data
    this.cargarMovimientosMuestra();
  }

  // === DATOS DE MUESTRA (FALLBACK) ===
  private cargarDatosMuestra(): void {
    this.productos = [
      {
        id: 1,
        name: 'Tensiómetro Digital',
        description: 'Tensiómetro automático de brazo con pantalla LCD',
        quantity: 15,
        category: 'Equipos de Diagnóstico',
        active: true,
        // Legacy mappings
        nombre: 'Tensiómetro Digital',
        descripcion: 'Tensiómetro automático de brazo con pantalla LCD',
        cantidadStock: 15,
        precio: 89.99,

        stockMinimo: 5,
        proveedor: 'MedTech Solutions',
        fechaActualizacion: new Date('2024-01-15'),
        activo: true
      },
      {
        id: 2,
        name: 'Estetoscopio Profesional',
        description: 'Estetoscopio de doble campana para adultos',
        quantity: 8,
        category: 'Equipos de Diagnóstico',
        active: true,
        // Legacy mappings
        nombre: 'Estetoscopio Profesional',
        descripcion: 'Estetoscopio de doble campana para adultos',
        cantidadStock: 8,
        precio: 45.50,

        stockMinimo: 10,
        proveedor: 'Medical Instruments Co.',
        fechaActualizacion: new Date('2024-01-10'),
        activo: true
      },
      {
        id: 3,
        name: 'Termómetro Infrarrojo',
        description: 'Termómetro sin contacto para frente',
        quantity: 0,
        category: 'Equipos de Diagnóstico',
        active: true,
        // Legacy mappings
        nombre: 'Termómetro Infrarrojo',
        descripcion: 'Termómetro sin contacto para frente',
        cantidadStock: 0,
        precio: 25.99,

        stockMinimo: 5,
        proveedor: 'ThermoTech',
        fechaActualizacion: new Date('2024-01-12'),
        activo: true
      }
    ];

    this.movimientos = [
      {
        id: 1,
        productoId: 1,
        productoNombre: 'Tensiómetro Digital',
        tipo: 'entrada',
        cantidad: 10,
        motivo: 'Compra a proveedor',
        fecha: new Date('2024-01-15'),
        usuario: 'admin@pulsovivo.com'
      },
      {
        id: 2,
        productoId: 2,
        productoNombre: 'Estetoscopio Profesional',
        tipo: 'salida',
        cantidad: 2,
        motivo: 'Venta a cliente',
        fecha: new Date('2024-01-14'),
        usuario: 'admin@pulsovivo.com'
      },
      {
        id: 3,
        productoId: 3,
        productoNombre: 'Termómetro Infrarrojo',
        tipo: 'salida',
        cantidad: 5,
        motivo: 'Venta a cliente',
        fecha: new Date('2024-01-12'),
        usuario: 'admin@pulsovivo.com'
      }
    ];

    this.productosFiltrados = [...this.productos];
  }

  // === NAVEGACIÓN ===
  cambiarVista(vista: 'inventario' | 'movimientos' | 'reportes'): void {
    this.vistaActual = vista;
  }

  // === GESTIÓN DE INVENTARIO ===
  private extraerCategorias(): void {
    this.categorias = [...new Set(this.productos.map(p => p.category || ''))];
  }

  private calcularEstadisticas(): void {
    this.estadisticas.totalProductos = this.productos.length;
    this.estadisticas.productosActivos = this.productos.filter(p => p.active || p.activo).length;
    this.estadisticas.productosStockBajo = this.productos.filter(p => (p.quantity || p.cantidadStock || 0) <= (p.stockMinimo || 5)).length;
    this.estadisticas.valorInventario = this.productos.reduce((total, p) => total + ((p.precio || 0) * (p.quantity || p.cantidadStock || 0)), 0);
  }

  // === FILTROS Y BÚSQUEDAS ===
  buscarProductos(): void {
    this.aplicarFiltros();
  }

  filtrarPorCategoria(): void {
    this.aplicarFiltros();
  }

  filtrarPorEstado(): void {
    this.aplicarFiltros();
  }

  private aplicarFiltros(): void {
    let productosFiltrados = [...this.productos];

    // Filtro por búsqueda
    if (this.terminoBusqueda) {
      const termino = this.terminoBusqueda.toLowerCase();
      productosFiltrados = productosFiltrados.filter(p =>
        (p.name || p.nombre || '').toLowerCase().includes(termino) ||
        (p.description || p.descripcion || '').toLowerCase().includes(termino) ||
        (p.proveedor || '').toLowerCase().includes(termino)
      );
    }

    // Filtro por categoría
    if (this.categoriaFiltro) {
      productosFiltrados = productosFiltrados.filter(p => p.category === this.categoriaFiltro);
    }

    // Filtro por estado
    if (this.estadoFiltro) {
      switch (this.estadoFiltro) {
        case 'activo':
          productosFiltrados = productosFiltrados.filter(p => p.active || p.activo);
          break;
        case 'inactivo':
          productosFiltrados = productosFiltrados.filter(p => !(p.active || p.activo));
          break;
        case 'stock_bajo':
          productosFiltrados = productosFiltrados.filter(p => (p.quantity || p.cantidadStock || 0) <= (p.stockMinimo || 5));
          break;
        case 'sin_stock':
          productosFiltrados = productosFiltrados.filter(p => (p.quantity || p.cantidadStock || 0) === 0);
          break;
      }
    }

    this.productosFiltrados = productosFiltrados;
  }

  limpiarFiltros(): void {
    this.terminoBusqueda = '';
    this.categoriaFiltro = '';
    this.estadoFiltro = '';
    this.productosFiltrados = [...this.productos];
  }

  // === GESTIÓN DE MODALES ===
  abrirModalCrear(): void {
    this.modoModal = 'crear';
    this.formularioProducto = {
      name: '',
      description: '',
      quantity: 0,
      category: '',
      active: true,
      // Legacy fields for form compatibility
      nombre: '',
      descripcion: '',
      cantidadStock: 0,
      activo: true
    };
    this.mostrarModal = true;
  }

  abrirModalEditar(producto: ProductoStock): void {
    this.modoModal = 'editar';
    this.productoSeleccionado = producto;
    this.formularioProducto = { ...producto };
    this.mostrarModal = true;
  }

  abrirModalMovimiento(producto: ProductoStock): void {
    this.modoModal = 'movimiento';
    this.productoSeleccionado = producto;
    this.formularioMovimiento = {
      tipo: 'entrada',
      cantidad: 0,
      motivo: ''
    };
    this.mostrarModal = true;
  }

  cerrarModal(): void {
    this.mostrarModal = false;
    this.productoSeleccionado = null;
  }

  // === OPERACIONES CRUD ===
  guardarProducto(): void {
    // Sync legacy fields with new API fields
    const productoData: Partial<ProductoApi> = {
      name: this.formularioProducto.name || this.formularioProducto.nombre || '',
      description: this.formularioProducto.description || this.formularioProducto.descripcion || '',
      quantity: this.formularioProducto.quantity || this.formularioProducto.cantidadStock || 0,
      category: this.formularioProducto.category || '',
      active: this.formularioProducto.active !== undefined ? this.formularioProducto.active : this.formularioProducto.activo || true
    };

    if (this.modoModal === 'crear') {
      this.apiService.crearProducto(productoData).subscribe({
        next: (producto) => {
          this.cargarProductos(); // Reload products from API
        },
        error: (error) => {
          console.error('Error creating product:', error);
          // Fallback to local creation
          const nuevoProducto: ProductoStock = {
            id: Math.max(...this.productos.map(p => p.id)) + 1,
            name: productoData.name || '',
            description: productoData.description || '',
            quantity: productoData.quantity || 0,
            category: productoData.category || '',
            active: productoData.active || true,
            // Legacy mappings
            nombre: productoData.name || '',
            descripcion: productoData.description || '',
            cantidadStock: productoData.quantity || 0,
            activo: productoData.active || true,
            fechaActualizacion: new Date()
          };
          this.productos.push(nuevoProducto);
          this.calcularEstadisticas();
          this.aplicarFiltros();
        }
      });
    } else if (this.modoModal === 'editar' && this.productoSeleccionado) {
      this.apiService.actualizarProducto(this.productoSeleccionado.id, productoData).subscribe({
        next: (producto) => {
          this.cargarProductos(); // Reload products from API
        },
        error: (error) => {
          console.error('Error updating product:', error);
          // Fallback to local update
          const index = this.productos.findIndex(p => p.id === this.productoSeleccionado!.id);
          if (index !== -1) {
            this.productos[index] = {
              ...this.productos[index],
              name: productoData.name || this.productos[index].name,
              description: productoData.description || this.productos[index].description,
              quantity: productoData.quantity !== undefined ? productoData.quantity : this.productos[index].quantity,
              category: productoData.category || this.productos[index].category,
              active: productoData.active !== undefined ? productoData.active : this.productos[index].active,
              // Legacy mappings
              nombre: productoData.name || this.productos[index].name,
              descripcion: productoData.description || this.productos[index].description,
              cantidadStock: productoData.quantity !== undefined ? productoData.quantity : this.productos[index].quantity,
              activo: productoData.active !== undefined ? productoData.active : this.productos[index].active,
              fechaActualizacion: new Date()
            };
          }
          this.calcularEstadisticas();
          this.aplicarFiltros();
        }
      });
    }

    this.cerrarModal();
  }

  eliminarProducto(producto: ProductoStock): void {
    const nombre = producto.name || producto.nombre || 'este producto';
    if (confirm(`¿Está seguro de que desea eliminar "${nombre}"?`)) {
      // TODO: Implement delete endpoint in inventory service
      console.warn('Delete endpoint not available in inventory service');
      
      // For now, deactivate the product instead of deleting
      const productoData: Partial<ProductoApi> = {
        ...producto,
        active: false
      };
      
      this.apiService.actualizarProducto(producto.id, productoData).subscribe({
        next: (producto) => {
          this.cargarProductos(); // Reload products from API
        },
        error: (error) => {
          console.error('Error deactivating product:', error);
          // Fallback to local removal
          const index = this.productos.findIndex(p => p.id === producto.id);
          if (index !== -1) {
            this.productos.splice(index, 1);
            this.calcularEstadisticas();
            this.aplicarFiltros();
          }
        }
      });
    }
  }

  toggleEstadoProducto(producto: ProductoStock): void {
    const newActiveState = !(producto.active || producto.activo);
    const productoData: Partial<ProductoApi> = {
      ...producto,
      active: newActiveState
    };

    this.apiService.actualizarProducto(producto.id, productoData).subscribe({
      next: (productoActualizado) => {
        this.cargarProductos(); // Reload products from API
      },
      error: (error) => {
        console.error('Error updating product status:', error);
        // Fallback to local update
        const index = this.productos.findIndex(p => p.id === producto.id);
        if (index !== -1) {
          this.productos[index].active = newActiveState;
          this.productos[index].activo = newActiveState;
          this.productos[index].fechaActualizacion = new Date();
          this.calcularEstadisticas();
        }
      }
    });
  }

  private cargarMovimientosMuestra(): void {
    // Generate sample movements data
    this.movimientos = [
      {
        id: 1,
        productoId: 1,
        productoNombre: 'Tensiómetro Digital',
        tipo: 'entrada',
        cantidad: 10,
        motivo: 'Compra proveedor',
        fecha: new Date(2024, 0, 15),
        usuario: 'admin@pulsovivo.com'
      },
      {
        id: 2,
        productoId: 2,
        productoNombre: 'Estetoscopio Profesional',
        tipo: 'salida',
        cantidad: 2,
        motivo: 'Venta cliente',
        fecha: new Date(2024, 0, 16),
        usuario: 'vendedor@pulsovivo.com'
      },
      {
        id: 3,
        productoId: 4,
        productoNombre: 'Guantes Desechables',
        tipo: 'entrada',
        cantidad: 25,
        motivo: 'Restock',
        fecha: new Date(2024, 0, 17),
        usuario: 'admin@pulsovivo.com'
      }
    ];
  }

  // === MOVIMIENTOS DE STOCK ===
  registrarMovimiento(): void {
    if (!this.productoSeleccionado) return;

    const nuevoMovimiento: MovimientoStock = {
      id: Math.max(...this.movimientos.map(m => m.id)) + 1,
      productoId: this.productoSeleccionado.id,
      productoNombre: this.productoSeleccionado.nombre || this.productoSeleccionado.name || '',
      tipo: this.formularioMovimiento.tipo,
      cantidad: this.formularioMovimiento.cantidad,
      motivo: this.formularioMovimiento.motivo,
      fecha: new Date(),
      usuario: this.authService.getCurrentUser()?.username || 'admin@pulsovivo.com'
    };

    this.movimientos.unshift(nuevoMovimiento);

    // Actualizar stock del producto usando API
    const cantidad = this.formularioMovimiento.cantidad;
    let quantityChange = 0;
    
    switch (this.formularioMovimiento.tipo) {
      case 'entrada':
        quantityChange = cantidad;
        break;
      case 'salida':
        quantityChange = -cantidad;
        break;
      case 'ajuste':
        // For adjustment, calculate the difference from current stock
        const currentStock = this.productoSeleccionado.quantity || this.productoSeleccionado.cantidadStock || 0;
        quantityChange = cantidad - currentStock;
        break;
    }

    this.apiService.actualizarStock(this.productoSeleccionado.id, quantityChange).subscribe({
      next: () => {
        this.cargarProductos(); // Reload products from API
      },
      error: (error) => {
        console.error('Error updating stock:', error);
        // Fallback to local update
        const index = this.productos.findIndex(p => p.id === this.productoSeleccionado!.id);
        if (index !== -1) {
          const currentStock = this.productos[index].quantity || this.productos[index].cantidadStock || 0;
          const newStock = Math.max(0, currentStock + quantityChange);
          this.productos[index].quantity = newStock;
          this.productos[index].cantidadStock = newStock;
          this.productos[index].fechaActualizacion = new Date();
          this.calcularEstadisticas();
          this.aplicarFiltros();
        }
      }
    });

    this.calcularEstadisticas();
    this.aplicarFiltros();
    this.cerrarModal();
  }

  // === UTILIDADES ===
  getEstadoStock(producto: ProductoStock): 'normal' | 'bajo' | 'agotado' {
    const stock = producto.quantity || producto.cantidadStock || 0;
    const minStock = producto.stockMinimo || 5;
    
    if (stock === 0) return 'agotado';
    if (stock <= minStock) return 'bajo';
    return 'normal';
  }

  getClaseEstado(estado: string): string {
    switch (estado) {
      case 'normal': return 'badge bg-success';
      case 'bajo': return 'badge bg-warning';
      case 'agotado': return 'badge bg-danger';
      default: return 'badge bg-secondary';
    }
  }

  formatearFecha(fecha: Date): string {
    return new Intl.DateTimeFormat('es-ES', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    }).format(fecha);
  }

  exportarInventario(): void {
    // Implementar exportación a CSV/Excel
    console.log('Exportando inventario...');
    alert('Funcionalidad de exportación en desarrollo');
  }

  async cerrarSesion(): Promise<void> {
    await this.authService.logout();
  }
}