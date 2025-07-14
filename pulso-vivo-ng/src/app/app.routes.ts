import { Routes } from '@angular/router';
import { AuthGuard } from './auth/auth.guard';
import { TiendaComponent } from './components/tienda/tienda.component';
import { AdministracionComponent } from './components/administracion/administracion.component';



export const routes: Routes = [
  {
    path: '',
    component: TiendaComponent
  },
  {
    path: 'tienda',
    component: TiendaComponent
  },
  {
    path: 'administracion',
    component: AdministracionComponent,
    canActivate: [AuthGuard]
  },


  {
    path: '**',
    redirectTo: ''
  }
];
